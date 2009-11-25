module Carat::Data
  class ProcClass < ClassInstance
  
  end
  
  class ProcInstance < ObjectInstance
    attr_reader :args, :contents
  
    def initialize(runtime, args, contents)
      @args, @contents = args, contents
      super(runtime, runtime.constants[:Proc])
    end
  end
end
