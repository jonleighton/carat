class Fixnum
  include Comparable
  
  def <=>(other)
    Carat.primitive "spaceship"
  end
  
  def +(other)
    Carat.primitive "plus"
  end
  
  def -(other)
    Carat.primitive "minus"
  end
  
  def to_s
    Carat.primitive "to_s"
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
