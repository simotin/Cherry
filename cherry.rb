require 'mkmf'

class Cherry
  ASSERT_EQUAL = :ASSERT_EQUAL

  @@types = ['int', 'void']
  @test_case = []

  def initialize(filename)
    puts "initialize"
    @funcTable = []
    @filename = filename
  end

  # 
  def add_test(function_name, args, assert_type, comment="")
    @tests << {:function_name =>function_name, :args=>args, :assert_type=>assert_type, :value=>value, :comment=>comment}
  end

  def run
    parse
    build
    exec_test
  end

  def exec_test
    require 'TestTarget'
    @test_cases.each do |test|
      ret = eval("TestTarget.#{test.function_name}")
      case test[:assert_type]
      when ASSERT_EQUAL
        if test[:value] == ret
          test_result << "success"
        else
          test_result << "failed #{test[:function_name]} returns #{ret}. You expect #{test[:value]}"
        end
      end
    end
  end
  def parse
    code = File.open(@filename) do |file|
      while line = file.gets
        if line.scan(/.*\s.*\(.*\);/).length == 1
          parts = line.split(' ')
          # 戻り値の型
          retType = getType(line)
          # カッコの中をカンマで区切る
          functionName = getFunctionName(line)
          # 引数
          args = getParams(line)
          @funcTable << {:ret_type =>ret_type, :function_name =>function_name, :args => args }
        end
      end
    end
    puts "functable:#{@func_table}"
  end
=begin

  def build
      extfile = File.open("ext.c","w")
      generateHeader(extfile)

      # テスト対象関数のラッパー関数生成
      generate_wrapper_function(extfile)

      # ライブラリ初期化コードの生成
      generate_init_code(extfile)

      extfile.close

      create_makefile @filename
      result = `make`
  end
  # ヘッダー部出力
  def generate_header(extfile)
    extfile.puts %{#include "ruby.h"}

    # 認識済みの関数のextern 宣言を出力
    @funcTable.each do |function|
      extfile.print "extern #{function[:ret_type]} #{function[:function_name]}("
        function[:args].each.with_index(1) do |arg, idx|
          extfile.print ', ' if idx != 1
          extfile.print "#{arg}"
        end
      extfile.puts ");"
    end
  end

  # ライブラリ初期化コード出力
  def generate_init_code(extfile)
    extfile.puts ""
    extfile.puts "void Init_TestTarget(void) {"
    extfile.puts ""
    extfile.puts "    VALUE module;"
    extfile.puts %{ module = rb_define_module( "TestTarget" );}

    # 認識済みの関数を登録
    @funcTable.each do |function|
        line = %{   rb_define_module_function( module, "#{function[:function_name]}", rb_test_#{function[:functionName]}, #{function[:args].length} );}
        extfile.puts line
    end
    extfile.puts "}"
  end

  def generate_wrapper_function(extfile)
    # ラッパー関数を作成
    @funcTable.each do |function|
      functionName = function[:function_name]
      args = function[:args]
      retType = function[:ret_type]

      extfile.puts ""
      extfile.print "VALUE rb_test_#{function[:function_name]}"
      extfile.print "(VALUE self"

      # ラッパー関数引数
      args.each.with_index(1) do |arg, idx|
          extfile.print ",VALUE param#{idx}"
      end
      extfile.print ") {"
      extfile.puts ""
      ret = ""
      case retType
      when 'int'
        extfile.puts "  int obj;"
      end

      extfile.print " obj = #{function_name}("
      args.each.with_index(1) do |arg, idx|
          extfile.print ',' if idx != 1
          case arg
          when 'int'
              extfile.print "FIX2INT(param#{idx})"
          when 'void'
              # 何も出力しない
          end
      end
      extfile.puts ");"
      case retType
      when 'int'
        extfile.puts "  return INT2FIX(obj);"
      when 'void'
        extfile.puts "  return Qnil;"
      end
      extfile.puts "}"
    end
  end

  def get_type(line)
    parts = line.split(' ')
    @@types.each do |type|
      if type == parts[0]
        return type
      end
    end
  end

  def get_function_name(line)
    parts = line.split(' ')
    parts[1].split('(')[0]
  end

  def get_args(line)
    parts = line.split(' ')
    parts[1].split('(')
    paramStr =  line.scan(/\(.*\)/).first
    paramStr.slice!(0)
    paramStr.slice!(-1)
    parts = paramStr.split(',')
    args = []
    parts.each do |paramStr|
      paramStr.strip!
      args << getType(paramStr.split(' ')[0])
    end
    return args
  end
=end
end
