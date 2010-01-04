module Kernel
  def puts
    Carat.primitive "puts"
  end

  def p(obj)
    puts obj.inspect
  end
  
  def proc(&block)
    Proc.new(&block)
  end
end
