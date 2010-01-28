module Kernel
  def raise(exception_or_string = nil, message = "(no message)")
    if exception_or_string.is_a?(Exception)
      Carat.primitive "raise"
    elsif exception_or_string.is_a?(String)
      raise Exception.new(exception_or_string)
    elsif exception_or_string == nil
      raise Exception.new(message)
    else
      raise exception_or_string.new(message)
    end
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
