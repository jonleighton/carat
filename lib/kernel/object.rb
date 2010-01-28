class Object
  include Kernel
  
  def initialize(*args, &block)
    # Do nothing by default
  end
  
  def !=(other)
    if self == other
      false
    else
      true
    end
  end
  
  def is_a?(test_class)
    klass = self.class
    
    while klass != nil
      if klass == test_class
        return true
      else
        klass = klass.superclass
      end
    end
    
    return false
  end
  
  def ==(other)
    Carat.primitive "equality_op"
  end
  
  def object_id
    Carat.primitive "object_id"
  end
  
  def class
    Carat.primitive "class"
  end
end
