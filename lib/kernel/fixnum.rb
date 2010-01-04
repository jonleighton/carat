class Fixnum
  def +(other)
    Carat.primitive "plus"
  end
  
  def -(other)
    Carat.primitive "minus"
  end
  
  def to_s
    Carat.primitive "to_s"
  end
  
  def inspect
    to_s
  end
end
