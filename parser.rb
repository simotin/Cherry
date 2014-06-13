# auto  double  int struct
# break else  long  switch
# case  enum  register  typedef
# char  extern  return  union
# const float short unsigned
# continue  for signed  void
# default goto  sizeof  volatile
# do  if  static  while
#
# int   hoge(void);
# int   *hoge(void);
# int*  hoge(void);
# int * hoge(void)
# void *
types = %w{char short int void long float double}

def parse_line(line)
  ary = line.split(' ')
  ary.each.with_index do |syntax,idx|
    if idx == 0
      prefix = check_prefix(syntax)
      # 変数 or 戻り値
      type = check_type(syntax)
      parse_status = :type_found
    else
      case parse_status
      when :type_found
        check_ptr syntax
        # 変数チェック
        if found_type != 'void'
          variable = check_variables(syntax)
          parse_status = :variable_found
        end
        # 関数チェック
        check_function(syntax) if parse_status == :type_found
      end
    end
  end
end

def check_prefix syntax
  prefixes = %w{unsigned signed extern static volatile}
  prefix = prefixes.index(syntax)
  return syntax if prefix
end

def check_type syntax
  ptr_count = 0
  types.each do |type|
    if syntax.match(/#{type}\*?+/)
      ptr_count = syntax.slice(/\*+/).length if syntax.include?('*')
      return {type: type, ptr_count: ptr_count}
    end
  end
  return nil
end

# ポインタ型チェック
def check_ptr syntax
  if '*' * syntax.length == syntax
    # ポインタ数 or nil を返す
    syntax.length
  end
end

def check_variables(syntax,type_info)
  # C言語の変数宣言を探す
  ary_count = 0
  ptr = syntax.slice(/^\*+/)
  if !ptr.nil?
    type_info[:ptr_count] += ptr.length
  end
  variable_name = syntax.slice!(/\*?+[_a-z]+[0-9a-z_]+/i)
  if variable_name
    if syntax.match(/;/)
      return {variablename: variable_name, ary_count: 0}
    else syntax.match(/\[\d+\];/)
      ary_count = syntax.scan(/\d+/).to_i
      return {variablename: variable_name, ary_count: ary_count}
    end
  end
  return nil
end

# 関数かどうかチェックする
def check_function(syntax,type_info)
  ptr = syntax.slice(/^\*+/)
  if !ptr.nil?
    type_info[:ptr_count] += ptr.length
  end
  function_name = syntax.slice!(/\*?+[_a-z]+[0-9a-z_]+/i)
  if function_name

  end

  # 前提としてスペースを区切りとして分割してきたけど、スキャナでスキャンしたほうが早い？
end
