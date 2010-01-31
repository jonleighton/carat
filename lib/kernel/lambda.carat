class Lambda
  # This is necessary because Object#new is implemented purely in the object language
  def self.new(*args, &block)
    Primitive.new(*args, &block)
  end
  
  def call(*args, &block)
    Primitive.call(*args, &block)
  end
end
