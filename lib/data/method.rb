module Carat::Data
  class MethodClass < ClassInstance
  end
  
  class MethodInstance < ObjectInstance
    attr_reader :argument_pattern, :contents
    
    def initialize(runtime, argument_pattern, contents)
      @argument_pattern, @contents = argument_pattern, contents
      super(runtime, runtime.constants[:Method])
    end
  end
end
