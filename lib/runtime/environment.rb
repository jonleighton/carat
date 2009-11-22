class Carat::Runtime
  class Environment
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants, :symbols, :run
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    def setup
      @object = constants[:Object] = Carat::Data::ObjectClass.new(runtime, nil)
      @module = constants[:Module] = Carat::Data::ModuleClass.new(runtime, @object)
      @class  = constants[:Class]  = Carat::Data::ClassClass.new(runtime, @module)
      
      # The class of the metaclass of Class is Class (but Class didn't exist when Class was set up)
      @class.metaclass.klass = @class
      
      # The above is a special case. In all other cases the class of a metaclass is the metaclass
      # of Class
      @object.metaclass.klass = @class.metaclass
      @module.metaclass.klass = @class.metaclass
      
      # The superclass of the metaclass of Object is just Class
      @object.metaclass.superclass = @class
      
      # Do this manually as the superclass and klass pointers were incorrect before
      [@object, @module, @class].each(&:add_primitives_to_method_table)
    end
    
    def load_kernel
      constants[:Kernel] = Carat::Data::ModuleInstance.new(runtime, :Kernel)
      constants[:Fixnum] = Carat::Data::FixnumClass.new(runtime, @object)
      constants[:Array]  = Carat::Data::ArrayClass.new(runtime, @object)
      
      [:object, :fixnum].each do |file|
        run(File.read(Carat::KERNEL_PATH + "/#{file}.rb"))
      end
      
      symbols[:self] = Carat::Data::ObjectInstance.new(runtime, @object)
    end
  end
end
