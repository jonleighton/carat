class Carat::Runtime
  class Class < Object
    attr_reader :name
    attr_accessor :superclass
    
    alias_method :metaclass, :singleton_class
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass and use that
    # "The superclass of the metaclass is the metaclass of the superclass" :)
    def initialize(runtime, name, superclass)
      @runtime, @name, @superclass = runtime, name, superclass
      @klass = MetaClass.new(runtime, self, superclass && superclass.metaclass)
      puts "Setting up #{self}, klass: #{klass}, real_klass:#{real_klass}, superclass: #{superclass}"
      include_bootstrap_class_modules
      puts
    end
    
    # The bootstrap module is the module containing specific behaviour and primitives for this class
    # For example, we have a +Fixnum+ class which behaves very specifically. It is "special", so we
    # need a way to define this behaviour. So there is a +Carat::Runtime::Bootstrap::Fixnum+ module
    # which is "hooked up" when the class +Fixnum+ is created, and when instances of the class
    # +Fixnum+ are created.
    def bootstrap_module
      name && Bootstrap.const_defined?(name) && Bootstrap.const_get(name)
    end
    
    def bootstrap_submodule(name)
      if bootstrap_module && bootstrap_module.const_defined?(name)
        bootstrap_module.const_get(name)
      end
    end
    
    # These are extensions to the object in the meta language which represents the class in the
    # object language. For example, +Carat::Runtime::Bootstrap::Fixnum::ClassExtensions+ has some
    # behaviour to keep track of current instances of +Fixnum+, because +Fixnum+ has the property
    # that you can't have two object representing the same number.
    def class_extensions_module
      bootstrap_submodule(:ClassExtensions)
    end
    
    # These are primitives which are added to the class in the object language. For example the 
    # class +Class+ has a primitive method +new+.
    def class_primitives_module
      bootstrap_submodule(:ClassPrimitives)
    end
    
    # These are extensions to the object in the meta language which represents an instance of the
    # class in the object language. For example, +Carat::Runtime::Bootstrap::Fixnum::ObjectExtensions+
    # adds a +value+ method to the objects representing +Fixnum+ instances, which stores the value
    # of the +Fixnum+ instance.
    def object_extensions_module
      bootstrap_submodule(:ObjectExtensions)
    end
    
    # These are primitives which are added to the instances in the object language. For example,
    # instances of the class +Array+ have a primitive method +length+.
    def object_primitives_module
      bootstrap_submodule(:ObjectPrimitives)
    end
    
    # Includes the relevant bootstrap modules for this class. These are:
    #   * Any specific extensions to this class
    #   * Any primitives to be defined on this class
    #   * Any primitives which were defined on the class of this class
    def include_bootstrap_class_modules
      include_extensions(class_extensions_module) if class_extensions_module
      include_primitives(class_primitives_module) if class_primitives_module
      
      # TODO: I think this is wrong. If we define a method Object.foo, and then create a
      # class A, we would require that A.foo also calls that method.
      if real_klass
        real_klass.included_primitives.each do |mod|
          include_primitives(mod)
        end
      end
    end
    
    # Includes the relevant bootstrap modules for an instance of this class. These are:
    #   * Any specific extensions to instances of this class
    #   * Any primitives to be defined on instances of this class
    #   * Any primitives to be defined on instances of the superclass, if there is one
    def include_bootstrap_object_modules(object)
      object.include_extensions(object_extensions_module) if object_extensions_module && object.real_klass == self
      object.include_primitives(object_primitives_module) if object_primitives_module
      superclass.include_bootstrap_object_modules(object) if superclass
    end
    
    def methods
      @methods ||= {}
    end
    
    def lookup_method(name)
      if methods[name]
        methods[name]
      else
        if superclass.nil?
          raise(Carat::CaratError, "method '#{self}##{name}' not found")
        else
          superclass.lookup_method(name)
        end
      end
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
