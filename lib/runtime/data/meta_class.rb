class Carat::Runtime
  class MetaClass < SingletonClass
    def to_s
      "<metaclass:#{parent}>"
    end
    
    def bootstrap_module
      parent.bootstrap_module
    end
    
    # These are extensions to the object in the meta language which represents the class in the
    # object language. For example, +Carat::Runtime::Bootstrap::Fixnum::SingletonExtensions+ has some
    # behaviour to keep track of current instances of +Fixnum+, because +Fixnum+ has the property
    # that you can't have two object representing the same number.
    def extensions_module
      bootstrap_submodule(:SingletonExtensions)
    end
    
    # These are primitives which are added to the class in the object language. For example the 
    # class +Class+ has a primitive method +new+.
    def primitives_module
      bootstrap_submodule(:SingletonPrimitives)
    end
  end
end
