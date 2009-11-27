module Carat::Data
  class NilClassClass < ClassInstance
    def instance
      @instance ||= NilClassInstance.new(runtime, self)
    end
  end
  
  class NilClassInstance < ObjectInstance
  end
end
