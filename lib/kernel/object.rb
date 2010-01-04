class Object
  include Kernel
  
  def initialize
    # Do nothing by default
  end
  
  def ==(other)
    Carat.primitive "equality_op"
  end
  
  def object_id
    Carat.primitive "object_id"
  end
end
