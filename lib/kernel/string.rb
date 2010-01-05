class String
  def inspect
    Carat.primitive "inspect"
  end
  
  def +(other)
    Carat.primitive "plus"
  end
  
  def <<(other)
    Carat.primitive "push"
  end

  def to_s
    self
  end
end
