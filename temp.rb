
def generate_struct_conv struct_info
	code = ""
	struct_name = struct_info[:struct_name]
	code += "VALUE #{struct_name}_to_rbobj(VALUE self, #{struct_name} *ptr) {\n"
	code += "\tVALUE cObj;\n"
	code += "\tVALUE obj;\n"
	code += "\tcObj = rb_const_get(rb_cObject, rb_intern(#{struct_name}));\n"
	code += "\tobj  = rb_class_new_instance(0, NULL, obj);\n"
	struct_info[:members].each do |member|
		case member[:type]
		when 'char'
			code += "\trb_iv_set(obj, \"#{member[:symbol_name]}\", rb_str_new2(ptr->#{member[:symbol_name]}));\n"
		else
			code += "\trb_iv_set(obj, \"#{member[:symbol_name]}\", ptr->#{member[:symbol_name]});\n"
		end
	end
	code += "\treturn obj;\n"
	code += "\t\n}"
	return code
end

#st_info = {:struct_name=>"ST_PERSON", :members=>[{:ary_count=>0, :type=>"int", :symbol_name=>"age", :ptr_count=>0}, {:ary_count=>128, :type=>"char", :symbol_name=>"name", :ptr_count=>0}]}
# puts generate_struct_conv st_info
