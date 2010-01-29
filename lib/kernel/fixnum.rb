class Fixnum
  include Comparable
  
  def <=>(other)
    Primitive.spaceship(other)
  end
  
  def +(other)
    Primitive.plus(other)
  end
  
  def -(other)
    Primitive.minus(other)
  end
  
  def to_s
    Primitive.to_s
  end
  
  # Unary -
  def --
    0 - self
  end
  
  # Unary +
  def ++
    self
  end
  
  def inspect
    to_s
  end
end
