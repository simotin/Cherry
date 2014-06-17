require './ractin'

ractin = Ractin.new("calc.c")
ractin.add_test('add', [1,2], Ractin::ASSERT_EQUAL, 3, "add test")
ractin.add_test('add', [1,2], Ractin::ASSERT_EQUAL, 4, "add test")
ractin.add_test('add', [3,2], Ractin::ASSERT_EQUAL, 5, "add test")
ractin.run
