class Carat::Runtime
  class Class < Object
    attr_reader :name
    attr_accessor :superclass
    
    alias_method :metaclass, :singleton_class
    
    # TODO: Change param order to runtime, superclass, name = nil
    def initialize(runtime, name, superclass)
      @name, @superclass = name, superclass
      super(runtime, get_klass(runtime))
    end
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass and use that
    # "The superclass of the metaclass is the metaclass of the superclass" :)
    def get_klass(runtime)
      MetaClass.new(runtime, self, superclass && superclass.metaclass)
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
    
    # Primitives for instances of this class are primitives for instances of the superclass,
    # plus any primitives defined for instances of this exact class
    def object_primitives
      unless @object_primitives
        @object_primitives = []
        @object_primitives += superclass.object_primitives if superclass
        @object_primitives << object_primitives_module if object_primitives_module
        @object_primitives.uniq
      end
      @object_primitives
    end
    
    # Class method primitives are class method primitives for the superclass, plus any class method
    # primitives defined for instances of this exact class
    def class_primitives
      unless @class_primitives
        @class_primitives = []
        @class_primitives += superclass.class_primitives if superclass
        @class_primitives << class_primitives_module if class_primitives_module
        @class_primitives.uniq
      end
      @class_primitives
    end
    
    def include_bootstrap_modules
      # Include extensions defined for this exact class
      include_extensions(class_extensions_module) if class_extensions_module
      
      # Include the class primitives
      include_primitives(*class_primitives)
      
      # Call super to include the instance-related bootstrap modules from the metaclass (because
      # classes are objects too)
      super
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
