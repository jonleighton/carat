class Carat::Runtime
  class Environment
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    def setup
      object_klass = constants[:Object] = Class.new(runtime, :Object, nil)
      class_klass  = constants[:Class]  = Class.new(runtime, :Class,  object_klass)
      
      # The class of the metaclass of Object is Class (but Class didn't exist when Object was set up)
      object_klass.metaclass.klass = class_klass
      
      # The class of the metaclass of Class is Class (but Class didn't exist when Class was set up)
      class_klass.metaclass.klass  = class_klass
      
      # Class exists now, so we won't have to explicitly set the class of the metaclass when
      # creating classes anymore
      
      # The superclass of the metaclass of Object is just Class
      object_klass.metaclass.superclass = class_klass
      
      # The superclass of the metaclass of Class adheres the the standard rule - it is the
      # metaclass of the superclass.
      class_klass.metaclass.superclass = class_klass.superclass.metaclass # = object_class.metaclass
      
      # TODO: Automate if possible
      object_klass.include_bootstrap_modules
      object_klass.metaclass.include_bootstrap_modules
      class_klass.include_bootstrap_modules
      class_klass.metaclass.include_bootstrap_modules
      
      constants[:Fixnum] = Class.new(runtime, :Fixnum, object_klass)
      constants[:Array]  = Class.new(runtime, :Array,  object_klass)
    end
  end
end
