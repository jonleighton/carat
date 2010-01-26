module Carat::Data
  class FalseClassClass < ClassInstance
    def instance
      @instance ||= FalseClassInstance.new(runtime, self)
    end
  end
  
  class FalseClassInstance < ObjectInstance
    def false_or_nil?
      true
    end
  end
end
