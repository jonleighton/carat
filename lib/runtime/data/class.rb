class Carat::Runtime
  class Class < Module
    def initialize(runtime, supr, name = nil)
      self.super = supr
      super(runtime, name)
    end
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass
    # and use that "The superclass of the metaclass is the metaclass of the superclass" :)
    def get_klass(runtime)
      MetaClass.new(runtime, self, superclass && superclass.metaclass)
    end
    
    # The super may be an include class for a module, but we want the first ancestor which is a 
    # "proper" class
    def superclass
      if self.super.instance_of?(Class)
        self.super
      else
        self.super && self.super.superclass
      end
    end
    
    def superclass=(klass)
      raise Carat::CaratError, "You can't set a non-class as the superclass" unless klass.is_a?(Class)
      self.super = klass
    end
    
    def to_s
      "<class:#{name}>"
    end
  end
end
