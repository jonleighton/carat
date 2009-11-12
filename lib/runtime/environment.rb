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
      @class  = constants[:Class]  = Class.new(runtime, @object, :Class)
      
      # The class of the metaclass of Class is Class (but Class didn't exist when Class was set up)
      @class.metaclass.klass = @class
      
      # The class of the metaclass of Object is the metaclass of Class (but Class didn't exist
      # when Object was set up)
      @object.metaclass.klass = @class.metaclass
      
      # Class exists now, so we won't have to explicitly set the class of the metaclass when
      # creating classes anymore
      
      # The superclass of the metaclass of Object is just Class
      @object.metaclass.superclass = @class
      
      # The superclass of the metaclass of Class adheres the the standard rule - it is the
      # metaclass of the superclass.
      @class.metaclass.superclass = @class.superclass.metaclass # = @object.metaclass
      
      # Do this manually as the superclass and klass pointers were incorrect before
      @object.include_bootstrap_modules
      @object.metaclass.include_bootstrap_modules
      @class.include_bootstrap_modules
      @class.metaclass.include_bootstrap_modules
      
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
