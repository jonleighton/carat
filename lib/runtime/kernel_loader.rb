class Carat::Runtime
  class KernelLoader
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants
    
    include Carat::Data
    
    LOAD_ORDER = [:kernel, :module, :class, :object, :comparable, :fixnum, :array, :string,
                  :nil_class, :true_class, :false_class, :lambda, :exception]
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    def run
      # Create SingletonClass - it has no class or super at this stage
      @singleton_class = constants[:SingletonClass] = SingletonClassClass.new(runtime, nil, nil)
      
      # The class of a singleton class is the singleton class of SingletonClass. In this case it's
      # a reference to itself.
      @singleton_class.singleton_class.klass = @singleton_class.singleton_class
      
      @object = constants[:Object] = ObjectClass.new(runtime, nil, nil)
      
      # Object's singleton class is a SingletonClass, so set the super pointer
      @object.singleton_class.super = @singleton_class
      
      # The class of a singleton class is the singleton class of SingletonClass
      @object.singleton_class.klass = @singleton_class.singleton_class
      
      # Module and Class should now set themselves up correctly
      @module = constants[:Module] = ModuleClass.new(runtime, nil, @object)
      @class  = constants[:Class]  = ClassClass.new(runtime, nil, @module)
      
      # Now position SingletonClass as a subclass of Class
      @singleton_class.super = @class
      @singleton_class.singleton_class.super = @class.singleton_class
      
      constants[:Kernel] = ModuleInstance.new(runtime, @module, :Kernel)
      
      create_classes(:Primitive, :Fixnum, :Array, :String, :Lambda, :Method,
                     :NilClass, :TrueClass, :FalseClass, :SingletonClass)
      
      LOAD_ORDER.each do |file|
        runtime.execute(Marshal.load(File.read(Carat::KERNEL_PATH + "/#{file}.marshal")))
      end
    end
    
    def create_classes(*names)
      names.each do |name|
        constants[name] = self.class.const_get("#{name}Class").new(runtime, @class, @object)
      end
    end
  end
end
