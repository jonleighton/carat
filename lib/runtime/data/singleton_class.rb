class Carat::Runtime
  class SingletonClass < Class
    attr_reader :parent
    
    # For a singleton class we do not create a metaclass (this would result in infinite recursion)
    # We set the class to be the class +Class+.
    def initialize(runtime, parent, superclass)
      @runtime, @parent, @superclass = runtime, parent, superclass
      @klass = superclass.klass if superclass
    end
    
    def to_s
      "<singleton_class:#{parent}>"
    end
  end
end
