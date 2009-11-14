class Carat::Runtime
  class Environment
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    def setup
      @object = constants[:Object] = Class.new(runtime, nil,     :Object)
      @module = constants[:Module] = Class.new(runtime, @object, :Module)
      @class  = constants[:Class]  = Class.new(runtime, @module, :Class)
      
      # The class of the metaclass of Class is Class (but Class didn't exist when Class was set up)
      @class.metaclass.klass = @class
      
      # The above is a special case. In all other cases the class of a metaclass is the metaclass
      # of Class
      @object.metaclass.klass = @class.metaclass
      @module.metaclass.klass = @class.metaclass
      
      # The superclass of the metaclass of Object is just Class
      @object.metaclass.superclass = @class
      
      # Do this manually as the superclass and klass pointers were incorrect before
      [@object, @module, @class].each do |klass|
        klass.include_bootstrap_modules
        klass.metaclass.include_bootstrap_modules
      end
      
      # The metaclass of Class needs to include its own primitives, as it is a special case in that
      # its class is the class Class, rather than another metaclass.
      @class.metaclass.singleton_include(*@class.metaclass.primitives)
    end
    
    def load_kernel
      constants[:Fixnum] = Class.new(runtime, @object, :Fixnum)
      constants[:Array]  = Class.new(runtime, @object, :Array)
    end
  end
end
