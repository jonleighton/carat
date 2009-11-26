module Kernel
  def p(obj)
    puts obj.inspect
  end
  
  def proc(&block)
    Proc.new(&block)
  end
end
