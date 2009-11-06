# TODO: Have a MetaClass subclass for semantic value
class Carat::Runtime
  class SingletonClass < Class
    # For a singleton class we do not create a metaclass (this would result in infinite recursion)
    # We set the class to be the class +Class+.
    def initialize(runtime, superclass)
      @runtime, @superclass = runtime, superclass
      @klass = runtime.constants[:Class]
    end
    
    def name
      "<singleton_class>"
    end
  end
end
