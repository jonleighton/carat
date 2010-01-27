module Kernel
  def raise
    Carat.primitive "raise"
  end
  
  def puts(obj)
    Carat.primitive "puts"
  end

  def p(obj)
    puts obj.inspect
  end
  
  def lambda(&block)
    Lambda.new(&block)
  end
  
  def yield
    Carat.primitive "yield"
  end
  
  def return
    Carat.primitive "return"
  end
end
