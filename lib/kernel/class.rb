class Class < Module
  def allocate
    Primitive.allocate
  end
  
  def superclass
    Primitive.superclass
  end
  
  def new(*args, &block)
    object = self.allocate
    object.initialize(*args, &block)
    object
  end
end
