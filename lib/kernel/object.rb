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
    Primitive.equal_to(other)
  end
  
  def object_id
    Primitive.object_id
  end
  
  def class
    Primitive.class
  end
end
