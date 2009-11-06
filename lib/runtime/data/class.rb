class Carat::Runtime
  class Class < Object
    class << self
      def object_extension
        @object_extension ||= Module.new
      end
      
      def extend_object(&extension)
        object_extension.module_eval(&extension)
      end
      
      def primitives
        @primitives ||= {}
      end
      
      def primitive(name, &definition)
        primitive_name = "primitive_#{name}"
        object_extension.module_eval do
          define_method(primitive_name, &definition)
        end
        primitives[name] = Primitive.new(primitive_name)
      end
    end
    
    attr_reader :name, :superclass
    
    extend Forwardable
    def_delegators :"self.class", :object_extension
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass and use that
    # "The superclass of the metaclass is the metaclass of the superclass" :)
    def initialize(runtime, name, superclass)
      @runtime, @name, @superclass = runtime, name, superclass
      @klass = SingletonClass.new(runtime, superclass && superclass.metaclass)
    end
    
    def methods
      @methods ||= self.class.primitives
    end
    
    alias_method :metaclass, :singleton_class
    
    def to_s
      "<class:#{name}>"
    end
  end
end
