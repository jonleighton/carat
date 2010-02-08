module Carat::Data
  class SingletonClassClass < ClassClass
    def new(owner, superclass)
      SingletonClassInstance.new(runtime, owner, superclass)
    end
  end
  
  class SingletonClassInstance < ClassInstance
    attr_reader :owner
    
    def initialize(runtime, owner, superclass)
      @owner = owner
      super(runtime, superclass && superclass.klass, superclass)
    end
    
    def to_s
      "<singleton_class:#{owner}>"
    end
  end
end
