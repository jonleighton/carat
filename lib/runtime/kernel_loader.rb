class Carat::Runtime
  class KernelLoader
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants
    
    LOAD_ORDER = [:kernel, :module, :class, :object, :comparable, :fixnum, :array, :string,
                  :nil_class, :true_class, :false_class, :lambda, :exception]
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    def run
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
      
      constants[:Kernel] = Carat::Data::ModuleInstance.new(runtime, :Kernel)
      create_classes(:Primitive, :Fixnum, :Array, :String, :Lambda, :Method,
                     :NilClass, :TrueClass, :FalseClass)
      
      LOAD_ORDER.each do |file|
        runtime.execute(Marshal.load(File.read(Carat::KERNEL_PATH + "/#{file}.marshal")))
      end
    end
    
    def create_classes(*names)
      names.each do |name|
        constants[name] = Carat::Data.const_get("#{name}Class").new(runtime, @object)
      end
    end
  end
end
