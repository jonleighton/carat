class Carat::Runtime
  class PartialAnswer
    attr_reader :value, :continuation
    
    def initialize(value, &continuation)
      @value, @continuation = value, continuation
    end
    
    def eval
      @continuation.call(@value)
    end
  end
end
