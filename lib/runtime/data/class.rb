class Carat::Runtime
  class Class < Object
    attr_reader :methods, :name, :superclass
    
    def initialize(name, superclass)
      super(nil) # TODO: Should be reference to Class object in the object language
      @name, @superclass = name, superclass
      @methods = {}
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
