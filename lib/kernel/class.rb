class Class < Module
  def allocate
    Carat.primitive "allocate"
  end
  
  def new(*args, &block)
    object = self.allocate
    object.initialize(*args, &block)
    object
  end
end
