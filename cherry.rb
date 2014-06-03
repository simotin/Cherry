require 'mkmf'

class Cherry
	@@types = ['int', 'void']
	
	def initialize(filename)
		puts "initialize"
		@funcTable = []
		@filename = filename
		create_makefile filename
		result = `make`
	end

	def generate
		# C言語のソースファイルから登録すべき関数名を取得する
		parse
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

