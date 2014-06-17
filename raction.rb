require 'mkmf'

class Cherry
  ASSERT_EQUAL = :ASSERT_EQUAL
  @@types = ['int', 'void']

  def initialize(filename)
    @funcTable = []
    @filename = filename
    @tests = []
  end

  # add test case
  def add_test(function_name, args, assert_type, value, comment="")
    h = {:function_name =>function_name, :args=>args, :assert_type=>assert_type, :value=>value, :comment=>comment}
    @tests << h
  end

  def run
    parse
    build
    exec_test
  end

  private

  # execute test cases
  def exec_test
    require './TestTarget'
    summary = {}
    details = []
    passed = 0
    failed = 0
    @tests.each do |test|
      exec_code = "TestTarget.#{test[:function_name]} "
      test[:args].each.with_index(1) do |arg, idx|
        exec_code += "," if idx != 1
        exec_code += "#{arg}"
      end

      ret = eval(exec_code)
      case test[:assert_type]
      when ASSERT_EQUAL
        if test[:value] == ret
          result = "passed"
          passed += 1
        else
          failed += 1
          result = "failed"
        end
        details << {:result=>result, :ret=>ret}
      end
      total  = @tests.length
      failed = total - passed
      summary = {:passed=>passed, :failed=>failed, :details=>details}
    end

    out_summary(summary)
  end

  def out_summary(summary)
    puts "================================================================================="
    puts "                              Test Summary                                       "
    puts "================================================================================="
    puts "[\e[32;1m#{summary[:passed]}\e[m] tests are passed, [\e[31;1m#{summary[:failed]}\e[m] test are failed in [#{summary[:passed] + summary[:failed]}] tests..."
    puts ""
    puts "============================== Test Result Details =============================="
    summary[:details].each.with_index do |detail, idx|
      message = "Test No.#{idx+1}, commnet:#{@tests[idx][:comment]}, [#{detail[:result]}]"
      if detail[:result] == "passed"
        puts message
      else
        puts "#{message}, #{@tests[idx][:function_name]} returned #{detail[:ret]}, But you expected #{@tests[idx][:value]}."
      end
    end
  end

  # parse C sourse code
  def parse
    code = File.open(@filename) do |file|
      while line = file.gets
        if line.scan(/.*\s.*\(.*\);/).length == 1
          parts = line.split(' ')
          ret_type = parse_type(line)
          function_name = parse_function_name(line)
          args = parse_args(line)
          @funcTable << {:ret_type =>ret_type, :function_name =>function_name, :args => args }
        end
      end
    end
  end

  def build
    extfile = File.open("ext.c","w")
    begin
      generate_header(extfile)
      generate_wrapper_function(extfile)
      generate_init_code(extfile)
    ensure
      extfile.close
    end
    create_makefile('TestTarget')
    result = `make`
  end

  def generate_header(extfile)
    extfile.puts %{#include "ruby.h"}

    # out function prototype
    @funcTable.each do |function|
      extfile.print "extern #{function[:ret_type]} #{function[:function_name]}("
        function[:args].each.with_index(1) do |arg, idx|
          extfile.print ', ' if idx != 1
          extfile.print "#{arg}"
        end
      extfile.puts ");"
    end
  end

  def generate_init_code(extfile)
    extfile.puts ""
    extfile.puts "void Init_TestTarget(void) {"
    extfile.puts ""
    extfile.puts "\tVALUE module;"
    extfile.puts %{\tmodule = rb_define_module( "TestTarget" );}

    # regist wapper functions
    @funcTable.each do |function|
        line = %{\trb_define_module_function( module, "#{function[:function_name]}", rb_test_#{function[:function_name]}, #{function[:args].length} );}
        extfile.puts line
    end
    extfile.puts "}"
  end

  def generate_wrapper_function(extfile)
    @funcTable.each do |function|
      function_name = function[:function_name]
      args = function[:args]
      retType = function[:ret_type]

      extfile.puts ""
      extfile.print "VALUE rb_test_#{function[:function_name]}"
      extfile.print "(VALUE self"

      args.each.with_index(1) do |arg, idx|
          extfile.print ",VALUE param#{idx}"
      end
      extfile.print ") {"
      extfile.puts ""
      ret = ""
      case retType
      when 'int'
        extfile.puts "\tint obj;"
      end

      extfile.print " obj = #{function_name}("
      args.each.with_index(1) do |arg, idx|
          extfile.print ',' if idx != 1
          case arg
          when 'int'
              extfile.print "FIX2INT(param#{idx})"
          when 'void'
          end
      end
      extfile.puts ");"
      case retType
      when 'int'
        extfile.puts "\treturn INT2FIX(obj);"
      when 'void'
        extfile.puts "\treturn Qnil;"
      end
      extfile.puts "}"
    end
  end

  def parse_type(line)
    parts = line.split(' ')
    @@types.each do |type|
      if type == parts[0]
        return type
      end
    end
  end

  def parse_function_name(line)
    parts = line.split(' ')
    parts[1].split('(')[0]
  end

  def parse_args(line)
    parts = line.split(' ')
    parts[1].split('(')
    paramStr =  line.scan(/\(.*\)/).first
    paramStr.slice!(0)
    paramStr.slice!(-1)
    parts = paramStr.split(',')
    args = []
    parts.each do |paramStr|
      paramStr.strip!
      args << parse_type(paramStr.split(' ')[0])
    end
    return args
  end

  def type_convert(type)
    case type
    when 'char', 'unsigned char', 'signed char', 'short', 'unsigned short','signed short', 'int','unsigned int', 'signed int', 'long', 'unsigned long', 'size_t'
      return Fixnum
    when 'void'
      return NilClass
    when 'float','double'
      return Float
    end
  end
end
