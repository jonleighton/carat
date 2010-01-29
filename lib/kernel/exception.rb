class Exception
  def initialize(message = "(no message)")
    @message = message
  end
  
  def to_s
    @message
  end
end

class StandardError < Exception; end

class NameError < StandardError
  def initialize(name)
    @name = name.to_s
  end
  
  def to_s
    "undefined local variable or method '" + @name + "'"
  end
end

class NoMethodError < NameError
  def to_s
    "method '" + @name + "' not found"
  end
end

class ArgumentError < StandardError; end
class RuntimeError < StandardError; end
