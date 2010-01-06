module Carat::Data
  class MethodClass < ClassInstance
  end
  
  class MethodInstance < ObjectInstance
    attr_reader :name, :argument_pattern, :contents
    
    def initialize(runtime, name, argument_pattern, contents)
      @name, @argument_pattern, @contents = name, argument_pattern, contents
      super(runtime, runtime.constants[:Method])
    end
    
    def to_s
      "<method:#{name}>"
    end
  end
end
