class Module
  def include(mod)
    Carat.primitive "include"
  end
  
  def ancestors
    Carat.primitive "ancestors"
  end
  
  def name
    Carat.primitive "name"
  end
  
  def inspect
    Carat.primitive "inspect"
  end
  
  def to_s
    Carat.primitive "to_s"
  end
end
