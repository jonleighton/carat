class Carat::Runtime
  class Class < Module
    # Any Object can have a singleton_class, but we can use the alias "metaclass" if we want to make
    # it explicit that the singleton class is specifically a metaclass
    alias_method :metaclass, :singleton_class
    
    def initialize(runtime, superclass, name = nil)
      @superclass = superclass
      super(runtime, name)
    end
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass
    # and use that "The superclass of the metaclass is the metaclass of the superclass" :)
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
    
    # Helper method to get a named submodule of the bootstrap module, if it exists
    def bootstrap_submodule(name)
      if bootstrap_module && bootstrap_module.const_defined?(name)
        bootstrap_module.const_get(name)
      end
    end
    
    # These are extensions to the object in the meta language which represents an instance of the
    # class in the object language. For example, +Carat::Runtime::Bootstrap::Fixnum::ObjectExtensions+
    # adds a +value+ method to the objects representing +Fixnum+ instances, which stores the value
    # of the +Fixnum+ instance.
    def extensions_module
      bootstrap_submodule(:ObjectExtensions)
    end
    
    # These are primitives which are added to the instances in the object language. For example,
    # instances of the class +Array+ have a primitive method +length+.
    def primitives_module
      bootstrap_submodule(:ObjectPrimitives)
    end
    
    # Modules defining primitives for instances of this class. For each instance, all of the 
    # primitive modules need to be singleton_included, so we get a full list using the inheritance
    # hierarchy.
    def primitives
      @primitives = []
      @primitives += superclass.primitives if superclass
      @primitives << primitives_module if primitives_module
      @primitives.uniq
    end
    
    def include_bootstrap_modules
      super
      
      # Set up the method table for the primitive methods in this class
      if primitives_module
        primitives_module.instance_methods.each do |method_name|
          methods[method_name.sub(/^primitive_/, '').to_sym] = Primitive.new(method_name.to_sym)
        end
      end
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
