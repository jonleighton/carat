class Carat::Runtime
  class SingletonClassInstance < ClassInstance
    attr_reader :parent
    
    # For a singleton class we do not create a metaclass (this would result in infinite recursion)
    # We set the class to be the class +Class+.
    def initialize(runtime, parent, superclass)
      @parent = parent
      super(runtime, superclass)
    end
    
    # Use the same class as the superclass. With the definitions in +Environment+, this ends up
    # being the metaclass of +Class+.
    def get_klass(runtime)
      superclass && superclass.klass
    end
    
    def singleton?
      true
    end
    
    def to_s
      "<singleton_class:#{parent}>"
    end
  end
end
