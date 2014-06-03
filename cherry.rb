require 'mkmf'

class Cherry
	@@types = ['int', 'void']
	
	def initialize(filename)
		puts "initialize"
		@funcTable = []
		@filename = filename
	end

	def generate
		# C言語のソースファイルから登録すべき関数名を取得する
		parse
		extfile = File.open("ext.c","w")
		extfile.puts %{#include "ruby.h"}
		extfile.puts ""
		extfile.puts "void Init_TestTarget(void) {"
		extfile.puts "	VALUE module;"
		extfile.puts %{	module = rb_define_module( "TestTarget" );}

		# ラッパー関数を作成
		@funcTable.each do |function|
			extfile.puts "VALUE rb_test_#{function[:functionName]} {"
			ret = ""
			case function[:retType]
				when 'int'
					ret = "INT2FIX("
						print %{#{function[:functionName]}(}
						if function[:args].length != 0
							function[:args].each do |arg|
							print "#{arg},"
						else
							print "void"
						end
				when 'void'
					ret = "void"
					print %{#{function[:functionName]}(}
					if function[:args].length != 0
						argStr
						function[:args].each do |arg|
						argStr += "#{arg}"
						end
						# 末尾の, を削除
						argStr.slice!(-1)
						puts  "#{argStr}) {"
						
					else
						print "void"
					end

			end
		end

		# 認識済みの関数を登録
		@funcTable.each do |function|
			line = %{	rb_define_module_function( module, "#{function[:functionName]}", rb_test_#{function[:functionName]}, #{function[:args].length} );}
			extfile.puts line
		end
		extfile.puts "}"
		extfile.close
		create_makefile filename
		result = `make`
	end

	def parse
		prototype = false
		code = File.open(@filename) do |file|
			while line = file.gets
				if line.scan(/.*\s.*\(.*\);/).length == 1
					parts = line.split(' ')

		 			# 戻り値の型
		 			rettype = getType(line)

		 			# カッコの中をカンマで区切る
		 			funcName = getFunctionName(line)

			 		# 引数
			 		args = getParams(line)
			 		@funcTable << {:rettype =>rettype, :functionName =>funcName, :args => args }
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
