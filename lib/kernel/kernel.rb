module Kernel
  def puts
    Carat.primitive "puts"
  end

  def p(obj)
    puts obj.inspect
  end
  
  def lambda(&block)
    Lambda.new(&block)
  end
end
