require 'mkmf'

class Cherry
	@@types = ['int', 'void']

	def initialize(filename)
		puts "initialize"
		@funcTable = []
		@filename = filename
	end

	def add(info)
	end
	
	# ヘッダー部出力
	def generateHeader(extfile)
		extfile.puts %{#include "ruby.h"}

		# 認識済みの関数のextern 宣言を出力
		@funcTable.each do |function|
			extfile.print "extern #{function[:retType]} #{function[:functionName]}("
			function[:args].each.with_index(1) do |arg, idx|
				extfile.print ', ' if idx != 1
				extfile.print "#{arg}"
			end
			extfile.puts ");"

		end
	end
	
	# ライブラリ初期化コード出力
	def generateInitCode(extfile)
		extfile.puts ""
		extfile.puts "void Init_TestTarget(void) {"
		extfile.puts ""
		extfile.puts "	VALUE module;"
		extfile.puts %{	module = rb_define_module( "TestTarget" );}

		# 認識済みの関数を登録
		@funcTable.each do |function|
			line = %{	rb_define_module_function( module, "#{function[:functionName]}", rb_test_#{function[:functionName]}, #{function[:args].length} );}
			extfile.puts line
		end
		extfile.puts "}"
	end

	def generateWrapperFunction(extfile)
		# ラッパー関数を作成
		@funcTable.each do |function|
			functionName = function[:functionName]
			args = function[:args]
			retType = function[:retType]

			extfile.puts ""
			extfile.print "VALUE rb_test_#{function[:functionName]}"
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
					extfile.puts "	int obj;"
			end

			
			extfile.print "	obj = #{functionName}("
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
					extfile.puts "	return INT2FIX(obj);"
				when 'void'
					extfile.puts "	return Qnil;"
			end
			extfile.puts "}"
		end
	end
	
	def run
		parse
		build
	end

	def build

		extfile = File.open("ext.c","w")
		generateHeader(extfile)

		# テスト対象関数のラッパー関数生成
		generateWrapperFunction(extfile)
		
		# ライブラリ初期化コードの生成
		generateInitCode(extfile)

		extfile.close

		create_makefile @filename
		result = `make`
	end

	def parse
		prototype = false
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
			 		@funcTable << {:retType =>retType, :functionName =>functionName, :args => args }
			 	end
		 	end
		end
		puts "functable:#{@funcTable}"
	end

	def getType(line)
		parts = line.split(' ')
		@@types.each do |type|
			if type == parts[0]
				return type
			end
		end
	end

	 def getFunctionName(line)
	   parts = line.split(' ')
	   parts[1].split('(')[0]
	 end

	 def getParams(line)
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
end
