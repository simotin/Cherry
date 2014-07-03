require 'strscan'

class RactinParser

	def initialize
		@types = %w{char short int long void}
	end

  def parse(file_path)
    code = File.open(file_path).read
    function_list = []
    s = StringScanner.new(code)
    # TODO 
    # ユーザーのインクルードチェック 将来的には読み込めるようにしたい
    # check_include s

    until s.eos? do
      # 修飾子
      prefix = s.scan(/unsigned\s|signed\s/)

      @types.each do |type|
        # TODO
        # 以下の正規表現だと
        # int * * * hoge;
        # みたいなパターンに対応できていない。
        syntax = s.scan(/#{type}\s?\*+\s|#{type}\s/)
        if syntax
          ptr_count = 0
          # ポインタチェック
          ptr_count = syntax.scan('*').length if syntax.include?('*')

          # シンボル名取得
          symbol_name = s.scan(/^[a-z$_][a-z0-9]+/i) 
          variable = check_variable s
          if variable
          else
            # 関数チェック
            function = check_function s
            unless function.nil?
              function[:function_name] = symbol_name
              return_info = { prefix: prefix, return_type: type, ptr_count: ptr_count }
              function[:return_info] = return_info
              function_list << function 
            end
          end
        end
      end
      s.scan_until(/\n|\r\n/)
    end
    return function_list
  end
  
	def check_struct s=nil
		code = open("calc.c").read
		s = StringScanner.new(code)
		
		struct_start = s.scan(/\s?+typedef\sstruct\s?+{/)
		if struct_start
			struct_body = s.scan_until(/}/)
			struct_end = s.scan_until(/\s?+[_a-z]+[a-z1-9_]+;/i)
			if struct_end
				struct_name = struct_end.strip!.delete!(";")
			else
				# TODO
				# 異常系 構造体の終了定義がない
			end
			members = []

			body_scanner = StringScanner.new(struct_body)
			until e = body_scanner.scan(/}/)
				body_scanner.scan_until(/\n|\r\n/)
				@types.each do |type|
	        syntax = body_scanner.scan(/\s?+#{type}\s?\*+\s+|\s?+#{type}\s+/)
	        if syntax
	          ptr_count = 0
	          # ポインタチェック
	          ptr_count = syntax.scan('*').length if syntax.include?('*')

	          # シンボル名取得
	          symbol_name = body_scanner.scan(/^[a-z$_][a-z0-9]+/i) 
	          variable = check_variable(body_scanner)
	          variable[:symbol_name] = symbol_name
	          members << variable
	        end
	      end
			end
			{struct_name: struct_name, members: members}
		end
		
	end

  private

  def check_include s
    include_str = s.scan(/#include\s+".*"/)
    if include_str
      file_path = include_str.slice(/".*"/).delete!("\"")
      # TODO ファイル存在チェック
      # ファイルがない場合はワーニングを出して継続
      # TODO ファイル読み込み
    end
  end

  def check_function s
    arg_str = s.scan(/\(.*\);/)
    unless arg_str.nil?
      arg_str.delete!("()")
      args = check_args arg_str
      return {args: args}
    end
    return nil
  end

  def check_variable s
    str = s.check_until(/;/)
    if str == ';'
      return {symbol_type: 'variable', ary_count: 0}
    elsif /\[\d+\]\s?+;/ =~ str
      ary_count = variable.slice(/\d+/).to_i
      return {symbol_type: 'variable', ary_count: ary_count}
    else
      return nil
    end
  end

  def check_args arg_str
    args = []
    args_list = arg_str.split(',')
    args_list.each do |arg_str|
      arg_str.strip!

      # 型修飾子チェック
      prefix = arg_str.slice!(/unsigned\s|signed\s/)

      @types.each do |type|
        # 一致すればそのまま切り取って、引数名のチェック
        syntax = arg_str.slice!(/#{type}\s?\*+\s?|#{type}\s/)
        if syntax
          ptr_count = 0

          # ポインタチェック
          ptr_count = syntax.slice(/\*+/).length if syntax.include?('*')

          # 変数名の有無
          if arg_str == ""
            arg_name = nil
          else
            arg_name = arg_str
          end

          args << {prefix: prefix, arg_type:type, arg_name: arg_name, ptr_count:ptr_count}
          next
        end
      end
    end
    return args
  end
end
parser = RactinParser.new
p parser.check_struct
