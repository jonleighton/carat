class Exception
  def initialize(message = "(no message)")
    @message = message
  end
  
  def to_s
    @message
  end
end
