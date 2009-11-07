# Here are some basic tests to make sure I don't introduce too many regressions
# Will replace with RubySpec when Carat becomes mature enough

require "test/unit"
require File.dirname(__FILE__) + "/../lib/carat"

class CaratTest < Test::Unit::TestCase
  def execute(code)
    Carat.execute(code)
  end
  
  def test_lit
    assert_equal("73", execute("73"))
  end
  
  def test_addition
    assert_equal("7", execute("4 + 3"))
  end
  
  def test_class_definition_and_method_calling
    code = <<-CODE
      class Foo
        def self.foo
          6
        end
        
        def foo
          2
        end
      end
      
      Foo.new.foo + Foo.foo
    CODE
    
    assert_equal("8", execute(code))
  end
  
  def test_class_reopening
    code = <<-CODE
      class Foo
        def a
          3
        end
        
        def b
          2
        end
      end
      
      class Foo
        def b
          1
        end
      end
      
      foo = Foo.new
      foo.a + foo.b
    CODE
    
    assert_equal("4", execute(code))
  end
end
