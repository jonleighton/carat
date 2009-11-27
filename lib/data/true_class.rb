module Carat::Data
  class TrueClassClass < ClassInstance
    def instance
      @instance ||= TrueClassInstance.new(runtime, self)
    end
  end
  
  class TrueClassInstance < ObjectInstance
  end
end
