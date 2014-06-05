require './Cherry'

test = Cherry.new("calc.c")
test.add_test('add', [1,2], Cherry::ASSERT_EQUAL, 3, "add test")
test.add_test('add', [1,2], Cherry::ASSERT_EQUAL, 4, "add test")
test.add_test('add', [3,2], Cherry::ASSERT_EQUAL, 5, "add test")
test.run