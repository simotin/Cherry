require 'strscan'

class RactinParser

  def parse(file_path)
    @types = %w{char short int long void}
    code = File.open(file_path).read

    function_list = []

    # parse start!
    s = StringScanner.new(code)
    # TODO 
    # ユーザーのインクルードチェック
    # 将来的には読み込めるようにしたい
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
            p variable
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
      arg_str.delete!("(")
      arg_str.delete!(")")
      args = check_args arg_str
      return {args: args}
    end
    return nil
  end

  def check_variable s
    variable = s.scan(/;/)
    if variable
      p symbol_type: 'variable', ary_count: 0
    else
      idx_str = s.scan(/\[\d+\];/)
      # TODO 添え字の英語は？
      if idx_str
        ary_count = idx_str.slice(/\d+/).to_i
        p symbol_type: 'variable', ary_count: ary_count
      end
    end
    return nil
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
