module Comparable
  def <=>(other)
    raise NotImplementedError
  end
  
  def <(other)
    (self <=> other) == -1
  end
  
  def >(other)
    (self <=> other) == 1
  end
  
  def <=(other)
    self < other || self == other
  end
  
  def >=(other)
    self > other || self == other
  end
end
