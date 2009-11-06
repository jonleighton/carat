class Carat::Runtime
  class Class < Object
    attr_reader :name, :superclass
    
    extend Forwardable
    def_delegators :"self.class", :object_extension
    
    alias_method :metaclass, :singleton_class
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass and use that
    # "The superclass of the metaclass is the metaclass of the superclass" :)
    def initialize(runtime, name, superclass)
      @runtime, @name, @superclass = runtime, name, superclass
      @klass = MetaClass.new(runtime, superclass && superclass.metaclass)
      
      include_extensions(extensions_module) if extensions_module
      include_primitives(primitives_module) if primitives_module
    end
    
    def bootstrap_module
      Bootstrap.const_defined?(name) && Bootstrap.const_get(name)
    end
    
    def methods
      @methods ||= {}
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
