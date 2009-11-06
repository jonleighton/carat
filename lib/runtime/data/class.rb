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
    
    attr_reader :methods, :runtime, :name, :superclass
    
    extend Forwardable
    def_delegators :"self.class", :object_extension
    
    def initialize(runtime, name, superclass)
      super(runtime, nil) # TODO: Should be reference to Class object in the object language
      @name, @superclass = name, superclass
      @methods = self.class.primitives
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
