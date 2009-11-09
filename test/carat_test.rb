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
      a.a + a.b + a.a + b.b
    CODE
    
    assert_equal("18", execute(code))
  end
  
  def test_object_superclass
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
      
      Foo.a + Foo.b + Foo.new.b
    CODE
    
    assert_equal("7", execute(code))
  end
  
  def test_object_superclass_primitives
    Carat::Runtime::Bootstrap::Object::ClassPrimitives.send(:define_method, :a) do
      runtime.constants[:Fixnum].get(3)
    end
    
    Carat::Runtime::Bootstrap::Object::ObjectPrimitives.send(:define_method, :b) do
      runtime.constants[:Fixnum].get(2)
    end
    
    code = <<-CODE
      class Foo
      end
      
      Foo.a + Foo.b + Foo.new.b
    CODE
    
    assert_equal("7", execute(code))
  ensure
    Carat::Runtime::Bootstrap::Object::ClassPrimitives.send(:remove_method, :a)
    Carat::Runtime::Bootstrap::Object::ObjectPrimitives.send(:remove_method, :b)
  end
  
  def test_class_class
    code = <<-CODE
      class Class
        def foo
          3
        end
      end
      
      class Foo
      end
      
      Foo.foo
    CODE
    
    assert_equal("3", execute(code))
  end
  
  def assert_primitive_modules(object, *expected_modules)
    included_modules = (class << object; self; end).included_modules
    actual_modules = included_modules.
      map { |mod| mod.to_s.sub("Carat::Runtime::Bootstrap::", "") }.
      find_all { |mod| mod =~ /Primitives$/ }
    expected_modules = expected_modules.map { |mod| "#{mod[0]}::#{mod[1]}Primitives" }
    
    assert_equal expected_modules.sort, actual_modules.sort
  end
  
  def test_environment
    runtime = Carat::Runtime.new
    constants = runtime.constants
    
    object = constants[:Object]
    objectm = object.metaclass
    objecti = Carat::Runtime::Object.new(runtime, object)
    
    klass = constants[:Class]
    klassm = klass.metaclass
    klassi = Carat::Runtime::Object.new(runtime, klass)
    
    foo = Carat::Runtime::Class.new(runtime, "Foo", object)
    foom = foo.metaclass
    fooi = Carat::Runtime::Object.new(runtime, foo)
    
    # Object
    assert_equal nil, object.superclass
    assert_equal object.metaclass, object.klass
    assert_equal klass, object.real_klass
    assert_primitive_modules(object,
      [:Object, :Class],  # Object should have class methods for Object (obviously)
      [:Object, :Object], # Object is an instance of Object
      [:Class, :Object]   # Object is an instance of Class
    )
    
    # Object.metaclass
    assert objectm.is_a?(Carat::Runtime::MetaClass)
    assert_equal klass, objectm.superclass
    assert_equal klass, objectm.klass
    assert_equal klass, objectm.real_klass
    assert_primitive_modules(objectm,
      [:Class, :Class],  # Object.metaclass is a subclass of Class
      [:Class, :Object], # Object.metaclass is an instnace of Class
      [:Object, :Class], # Object.metaclass is a subclass of Object
      [:Object, :Object] # Object.metaclass is an instance of Object
    )
    
    # Object.new
    assert_equal object, objecti.klass
    assert_primitive_modules(objecti,
      [:Object, :Object] # Object.new is an instance of Object
    )
    
    # Class
    assert_equal object, klass.superclass
    assert_equal klass.metaclass, klass.klass
    assert_equal klass, klass.real_klass
    assert_primitive_modules(klass,
      [:Class, :Class],   # Class should have class methods for Class (obviously)
      [:Object, :Class],  # Class is a subclass of Object
      [:Object, :Object], # Class is an instance of Object
      [:Class, :Object]   # Class is an instance of Class
    )
    
    # Class.metaclass
    assert klassm.is_a?(Carat::Runtime::MetaClass)
    assert_equal objectm, klassm.superclass
    assert_equal klass, klassm.klass
    assert_equal klass, klassm.real_klass
    assert_primitive_modules(klassm,
      [:Class, :Class],  # Class.metaclass is a subclass of Class
      [:Class, :Object], # Class.metaclass is an instance of Class
      [:Object, :Class], # Class.metaclass is a subclass of Object
      [:Object, :Object] # Class.metaclass is an instance of Object
    )
    
    # Class.new
    assert_equal klass, klassi.klass
    assert_primitive_modules(klassi,
      [:Class, :Object], # Class.new is an instance of Class
      [:Object, :Object] # Class is a subclass of Object
    )
    
    # Foo
    assert_equal object, foo.superclass
    assert_equal foo.metaclass, foo.klass
    assert_equal klass, foo.real_klass
    assert_primitive_modules(foo,
      [:Object, :Class],  # Foo is a subclass of Object
      [:Object, :Object], # Foo is an instance of Object
      [:Class, :Object]   # Foo is an instance of Class
    )
    
    # Foo.metaclass
    assert foom.is_a?(Carat::Runtime::MetaClass)
    assert_equal objectm, foom.superclass
    assert_equal klass, foom.klass
    assert_equal klass, foom.real_klass
    assert_primitive_modules(foom,
      [:Class, :Class],  # Foo.metaclass is a subclass of Class
      [:Class, :Object], # Foo.metaclass is an instance of Class
      [:Object, :Class], # Foo.metaclass is a subclass of Object
      [:Object, :Object] # Foo.metaclass is an instance of Object
    )
    
    # Foo.new
    assert_equal foo, fooi.klass
    assert_primitive_modules(fooi,
      [:Object, :Object] # Foo is a subclass of Object
    )
  end
end
