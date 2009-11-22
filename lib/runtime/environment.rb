class Carat::Runtime
  class Environment
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants, :symbols, :run
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    # TODO: Refactor to avoid repetition
    
    def setup
      @object = constants[:Object] = ObjectClass.new(runtime, nil, :Object)
      @module = constants[:Module] = ModuleClass.new(runtime, @object, :Module)
      @class  = constants[:Class]  = ClassClass.new(runtime, @module, :Class)
      
      # The class of the metaclass of Class is Class (but Class didn't exist when Class was set up)
      @class.metaclass.klass = @class
      
      # The above is a special case. In all other cases the class of a metaclass is the metaclass
      # of Class
      @object.metaclass.klass = @class.metaclass
      @module.metaclass.klass = @class.metaclass
      
      # The superclass of the metaclass of Object is just Class
      @object.metaclass.superclass = @class
      
      # Set up the Kernel module and include it in Object
      # TODO: Can this happen later?
      @kernel = constants[:Kernel] = KernelModule.new(runtime, :Kernel)
      @object.super = IncludeClassInstance.new(runtime, @kernel, nil)
      
      # Do this manually as the superclass and klass pointers were incorrect before
      [@object, @module, @class, @kernel].each(&:add_primitives_to_method_table)
    end
    
    def load_kernel
      constants[:Fixnum] = FixnumClass.new(runtime, @object, :Fixnum)
      constants[:Array]  = ArrayClass.new(runtime, @object, :Array)
      
      [:object, :fixnum].each do |file|
        run(File.read(Carat::KERNEL_PATH + "/#{file}.rb"))
      end
      
      symbols[:self] = ObjectInstance.new(runtime, @object)
    end
  end
end
