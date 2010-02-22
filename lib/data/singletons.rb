module Carat::Data
  class SingletonObjectClass < ClassInstance
    def instance
      @instance ||= instance_class.new(runtime, self)
    end
  end
  
  class FalseClassClass < SingletonObjectClass; end
  class FalseClassInstance < ObjectInstance;    end
  class TrueClassClass < SingletonObjectClass;  end
  class TrueClassInstance < ObjectInstance;     end
  class NilClassClass < SingletonObjectClass;   end
  class NilClassInstance < ObjectInstance;      end
end
