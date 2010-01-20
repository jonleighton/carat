class Lambda
  def self.new(*args, &block)
    Carat.primitive "new"
  end
  
  def call(*args)
    Carat.primitive "call"
  end
end
