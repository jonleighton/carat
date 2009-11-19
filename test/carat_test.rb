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
      
      Foo.a + Foo.b + Foo.new.b
    CODE
    
    assert_equal("7", execute(code))
  end
  
  def test_object_primitives
    Carat::Runtime::Bootstrap::Object::SingletonPrimitives.send(:define_method, :a) do
      runtime.constants[:Fixnum].get(3)
    end
    
    Carat::Runtime::Bootstrap::Object::Primitives.send(:define_method, :b) do
      runtime.constants[:Fixnum].get(2)
    end
    
    code = <<-CODE
      class Foo
      end
      
      Foo.a + Foo.b + Foo.new.b
    CODE
    
    assert_equal("7", execute(code))
  ensure
    Carat::Runtime::Bootstrap::Object::SingletonPrimitives.send(:remove_method, :a)
    Carat::Runtime::Bootstrap::Object::Primitives.send(:remove_method, :b)
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
      
      Foo.a + (class << Foo; self; end).b
    CODE
    
    assert_equal("5", execute(code))
    
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
  
  def test_class_primitives
    Carat::Runtime::Bootstrap::Class::Primitives.send(:define_method, :a) do
      runtime.constants[:Fixnum].get(3)
    end
    
    Carat::Runtime::Bootstrap::Class::SingletonPrimitives.send(:define_method, :b) do
      runtime.constants[:Fixnum].get(2)
    end
    
    code = <<-CODE
      class Foo
      end
      
      Foo.a + (class << Foo; self; end).b
    CODE
    
    assert_equal("5", execute(code))
  ensure
    Carat::Runtime::Bootstrap::Class::Primitives.send(:remove_method, :a)
    Carat::Runtime::Bootstrap::Class::SingletonPrimitives.send(:remove_method, :b)
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
      bar.a + bar.c + Foo.b
    CODE
    
    assert_equal("11", execute(code))
  end
  
  def assert_bootstrap_modules(object, type, *expected_modules)
    included_modules = (class << object; self; end).included_modules
    actual_modules = included_modules.map(&:to_s).
      find_all { |mod| mod =~ /::#{type}$/ }.
      map { |mod| mod.sub("Carat::Runtime::Bootstrap::", "") }.
      map { |mod| mod.sub("::#{type}", "") }
    expected_modules = expected_modules.map(&:to_s)
    
    assert_equal expected_modules.sort, actual_modules.sort
  end
  
  def assert_primitive_modules(object, *expected_modules)
    assert_bootstrap_modules(object, :Primitives, *expected_modules)
  end
  
  def assert_singleton_primitive_modules(object, *expected_modules)
    assert_bootstrap_modules(object, :SingletonPrimitives, *expected_modules)
  end
  
  def test_environment
    runtime = Carat::Runtime.new
    constants = runtime.constants
    
    object = constants[:Object]
    objectm = object.metaclass
    objecti = Carat::Runtime::Object.new(runtime, object)
    
    mod = constants[:Module]
    modm = mod.metaclass
    modi = Carat::Runtime::Object.new(runtime, mod)
    
    klass = constants[:Class]
    klassm = klass.metaclass
    klassi = Carat::Runtime::Object.new(runtime, klass)
    
    foo = Carat::Runtime::Class.new(runtime, object, "Foo")
    foom = foo.metaclass
    fooi = Carat::Runtime::Object.new(runtime, foo)
    
    # Object
    assert_equal nil, object.super
    assert_equal object.metaclass, object.klass
    assert_equal klass, object.real_klass
    assert_primitive_modules(object,
      :Class,  # Object is an instance of Class
      :Object, # Object is an Object
      :Module  # Object is a Module
    )
    # Object should have singleton methods for Object (obviously)
    assert_singleton_primitive_modules(object, :Object)
    
    # Object.metaclass
    assert objectm.is_a?(Carat::Runtime::MetaClass)
    assert_equal klass, objectm.super
    assert_equal klassm, objectm.klass
    assert_equal klass, objectm.real_klass
    assert_equal klass, objectm.super
    assert_primitive_modules(objectm,
      :Class,  # Object.metaclass is an instance of Class
      :Object, # Object.metaclass is an Object
      :Module  # Object.metaclass is a Module
    )
    assert_singleton_primitive_modules(objectm,
      :Class,  # Object.metaclass is a subclass of Class
      :Object, # Object.metaclass is a subclass of Object
      :Module  # Object.metaclass is a subclass of Module
    )
    
    # Object.new
    assert_equal object, objecti.klass
    assert_primitive_modules(objecti, :Object) # Object.new is an instance of Object
    
    # Module
    assert_equal object, mod.super
    assert_equal mod.metaclass, mod.klass
    assert_equal klass, mod.real_klass
    assert_primitive_modules(mod,
      :Object, # Module is an Object
      :Module, # Module is a Module
      :Class   # Module is an instance of Class
    )
    assert_singleton_primitive_modules(mod,
      :Object, # Module is a subclass of Object
      :Module  # Module should have its own class methods (obviously)
    )
    
    # Module.metaclass
    assert modm.is_a?(Carat::Runtime::MetaClass)
    assert_equal klassm, modm.klass
    assert_equal klass, modm.real_klass
    assert_equal objectm, modm.super
    assert_primitive_modules(objectm,
      :Class,  # Module.metaclass is an instance of Class
      :Object, # Module.metaclass is an Object
      :Module  # Module.metaclass is a Module
    )
    assert_singleton_primitive_modules(objectm,
      :Class,  # Module.metaclass is a subclass of Class
      :Object, # Module.metaclass is a subclass of Object
      :Module  # Module.metaclass is a subclass of Module
    )
    
    # Module.new
    assert_equal mod, modi.klass
    assert_primitive_modules(modi,
      :Module, # Module.new is an instance of Module
      :Object  # Module.new is an Object
    )
    
    # Class
    assert_equal mod, klass.super
    assert_equal klass.metaclass, klass.klass
    assert_equal klass, klass.real_klass
    assert_primitive_modules(klass,
      :Object, # Class is an Object
      :Class,  # Class is an instance of Class
      :Module  # Class is a Module
    )
    assert_singleton_primitive_modules(klass,
      :Class,  # Class should have class methods for Class (obviously)
      :Object, # Class is a subclass of Object
      :Module  # Class is a subclass of Module
    )
    
    # Class.metaclass
    assert klassm.is_a?(Carat::Runtime::MetaClass)
    assert_equal modm, klassm.super
    assert_equal klass, klassm.klass
    assert_equal klass, klassm.real_klass
    assert_equal modm, klassm.super
    assert_primitive_modules(klassm,
      :Class,  # Class.metaclass is an instance of Class
      :Object, # Class.metaclass is an Object
      :Module  # Class.metaclass is a Module
    )
    assert_singleton_primitive_modules(klassm,
      :Class,  # Class.metaclass is a subclass of Class
      :Object, # Class.metaclass is a subclass of Object
      :Module  # Class.metaclass is a subclass of Module
    )
    
    # Class.new
    assert_equal klass, klassi.klass
    assert_primitive_modules(klassi,
      :Class,  # Class.new is an instance of Class
      :Module, # Class.new is a Module
      :Object  # Class.new is an Object
    )
    
    # Foo
    assert_equal object, foo.super
    assert_equal foo.metaclass, foo.klass
    assert_equal klass, foo.real_klass
    assert_primitive_modules(foo,
      :Class,  # Foo is an instance of Class
      :Module, # Foo is a Module
      :Object  # Foo is an Object
    )
    assert_singleton_primitive_modules(foo, :Object) # Foo is a subclass of Object
    
    # Foo.metaclass
    assert foom.is_a?(Carat::Runtime::MetaClass)
    assert_equal objectm, foom.super
    assert_equal klassm, foom.klass
    assert_equal klass, foom.real_klass
    assert_equal objectm, foom.super
    assert_primitive_modules(foom,
      :Class,  # Foo.metaclass is an instance of Class
      :Object, # Foo.metaclass is an Object
      :Module  # Foo.metaclass is a Module
    )
    assert_singleton_primitive_modules(foom,
      :Class,  # Foo.metaclass is a subclass of Class
      :Object, # Foo.metaclass is a subclass of Object
      :Module  # Foo.metaclass is a subclass of Module
    )
    
    # Foo.new
    assert_equal foo, fooi.klass
    assert_primitive_modules(fooi, :Object) # Foo is a subclass of Object
  end
end
