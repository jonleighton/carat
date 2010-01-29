module Kernel
  def raise(exception_or_string = nil, message = "(no message)")
    if exception_or_string.is_a?(Exception)
      Primitive.raise exception_or_string
    elsif exception_or_string.is_a?(String)
      Primitive.raise RuntimeError.new(exception_or_string)
    elsif exception_or_string == nil
      Primitive.raise RuntimeError.new(message)
    else
      Primitive.raise exception_or_string.new(message)
    end
  end
  
  def puts(obj = "\n")
    Primitive.puts(obj)
  end

  def p(obj)
    puts obj.inspect
  end
  
  def lambda(&block)
    Lambda.new(&block)
  end
  
  def yield(*args)
    Primitive.yield(*args)
  end
  
  def return(value)
    Primitive.return(value)
  end
end
