class Carat::Runtime
  class Primitive
    attr_reader :definition
  
    def initialize(definition)
      @definition = definition
    end
  end
end
