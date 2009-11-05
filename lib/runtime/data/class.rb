class Carat::Runtime
  class Class < Object
    attr_reader :methods, :name, :superclass, :object_class
    
    class << self
      def primitives
        @primitives ||= {}
      end
      
      def primitive(name, &definition)
        primitives[name] = Primitive.new(definition)
      end
    end
    
    def initialize(name, superclass)
      super(nil) # TODO: Should be reference to Class object in the object language
      @name, @superclass = name, superclass
      @methods = self.class.primitives
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
