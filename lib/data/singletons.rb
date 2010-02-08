module Carat::Data
  class SingletonObjectClass < ClassInstance
    # TODO: Get rid of this, have Runtime keep hold of the instance, and redefine new to throw
    # an exception in kernel/
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
