class Carat::Runtime
  class Method
    attr_reader :args, :contents
    
    def initialize(args, contents)
      @args, @contents = args, contents
    end
  end
end
