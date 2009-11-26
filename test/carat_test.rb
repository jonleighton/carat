# Here are some basic tests to make sure I don't introduce too many regressions
# Will replace with RubySpec when Carat becomes mature enough

require "test/unit"
require File.dirname(__FILE__) + "/../lib/carat"

class CaratTest < Test::Unit::TestCase
  def execute(code)
    old_stdout = $stdout
    output = StringIO.new
    $stdout = output
    Carat.execute(code)
    $stdout = old_stdout
    output.string
  end
  
  def test_lit
    assert_equal("73\n", execute("puts 73"))
  end
  
  def test_addition
    assert_equal("7\n", execute("puts 4 + 3"))
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
      
      puts Foo.new.foo + Foo.foo
    CODE
    
    assert_equal("8\n", execute(code))
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
      puts foo.a + foo.b
    CODE
    
    assert_equal("4\n", execute(code))
  end
  
  def test_subclassing
    code = <<-CODE
      class A
        def a
          4
        end
        
        def b
          2
        end
      end
      
      class B < A
        def b
          8
        end 
      end
      
      a = A.new
      b = B.new
      puts a.a + a.b + a.a + b.b
    CODE
    
    assert_equal("18\n", execute(code))
  end
  
  def test_object
    code = <<-CODE
      class Object
        def self.a
          3
        end
        
        def b
          2
        end
      end
      
      class Foo
      end
      
      puts Foo.a + Foo.b + Foo.new.b
    CODE
    
    assert_equal("7\n", execute(code))
  end
  
  def test_class
    code = <<-CODE
      class Class
        def a
          3
        end
        
        def self.b
          2
        end
      end
      
      class Foo
      end
      
      puts Foo.a + (class << Foo; self; end).b
    CODE
    
    assert_equal("5\n", execute(code))
    
    code = <<-CODE
      class Class
        def self.a
          2
        end
      end
      
      class Foo
      end
      
      Foo.a
    CODE
    
    assert_raises(Carat::CaratError) { execute(code) }
  end
  
  def test_module_including
    code = <<-CODE
      module Foo
        def a
          5
        end
        
        def self.b
          2
        end
      end
      
      module Foo2
        def c
          4
        end
      end

      class Bar
        include Foo
        include Foo2
      end
      
      bar = Bar.new
      puts bar.a + bar.c + Foo.b
    CODE
    
    assert_equal("11\n", execute(code))
  end
  
  def test_multiple_assignment
    code = <<-CODE
      x, *y = 5, 3, 6

      puts x
      p y
    CODE
    
    assert_equal("5\n[3, 6]\n", execute(code))
  end
  
  def test_block_without_closure
    code = <<-CODE
      def foo
        yield(2)
      end

      foo { |x|
        puts x + 5
      }
    CODE
    
    assert_equal("7\n", execute(code))
  end
  
  def test_block_with_closure
    code = <<-CODE
      class Foo
        def a
          foo = 5
          yield
        end
      end

      foo = 2
      block = proc { puts foo }
      foo = 7
      Foo.new.a(&block)
    CODE
    
    assert_equal("7\n", execute(code))
  end
  
  def test_environment
    runtime = Carat::Runtime.new
    constants = runtime.constants
    
    object = constants[:Object]
    objectm = object.metaclass
    objecti = Carat::Data::ObjectInstance.new(runtime, object)
    
    mod = constants[:Module]
    modm = mod.metaclass
    modi = Carat::Data::ModuleInstance.new(runtime)
    
    klass = constants[:Class]
    klassm = klass.metaclass
    klassi = Carat::Data::ClassInstance.new(runtime, klass)
    
    foo = Carat::Data::ClassInstance.new(runtime, object, :Foo)
    foom = foo.metaclass
    fooi = Carat::Data::ObjectInstance.new(runtime, foo)
    
    # Object
    assert_equal nil, object.superclass
    assert_equal object.metaclass, object.klass
    assert_equal klass, object.real_klass
    
    # Object.metaclass
    assert_equal klass, objectm.super
    assert_equal klassm, objectm.klass
    assert_equal klass, objectm.real_klass
    assert_equal klass, objectm.super
    
    # Object.new
    assert_equal object, objecti.klass
    
    # Module
    assert_equal object, mod.super
    assert_equal mod.metaclass, mod.klass
    assert_equal klass, mod.real_klass
    
    # Module.metaclass
    assert_equal klassm, modm.klass
    assert_equal klass, modm.real_klass
    assert_equal objectm, modm.super
    
    # Module.new
    assert_equal mod, modi.real_klass
    
    # Class
    assert_equal mod, klass.super
    assert_equal klass.metaclass, klass.klass
    assert_equal klass, klass.real_klass
    
    # Class.metaclass
    assert_equal modm, klassm.super
    assert_equal klass, klassm.klass
    assert_equal klass, klassm.real_klass
    assert_equal modm, klassm.super
    
    # Class.new
    assert_equal klass, klassi.real_klass
    
    # Foo
    assert_equal object, foo.super
    assert_equal foo.metaclass, foo.klass
    assert_equal klass, foo.real_klass
    
    # Foo.metaclass
    assert_equal objectm, foom.super
    assert_equal klassm, foom.klass
    assert_equal klass, foom.real_klass
    assert_equal objectm, foom.super
    
    # Foo.new
    assert_equal foo, fooi.klass
  end
end
