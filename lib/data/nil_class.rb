module Carat::Data
  class NilClassClass < ClassInstance
    def instance
      @instance ||= NilClassInstance.new(runtime, self)
    end
  end
  
  class NilClassInstance < ObjectInstance
    def false_or_nil?
      true
    end
  end
end
