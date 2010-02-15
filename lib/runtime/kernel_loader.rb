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
      # Create SingletonClass and Object. The super pointers of SingletonClass, SingletonClass',
      # Object and Object' will be nil. The klass pointers of SingletonClass' and Object' will also
      # be nil.
      @singleton_class = constants[:SingletonClass] = SingletonClassClass.new(runtime, nil, nil)
      @object          = constants[:Object]         = ObjectClass.new(runtime, nil, nil)
      
      # Set the klass pointers of SingletonClass' and Object'
      # The class of any singleton class is SingletonClass
      @singleton_class.singleton_class.klass = @singleton_class
      @object.singleton_class.klass          = @singleton_class
      
      # Create Module and Class. The super and klass pointers can be inferred correctly at this 
      # stage based on the superclass given.
      @module = constants[:Module] = ModuleClass.new(runtime, nil, @object)
      @class  = constants[:Class]  = ClassClass.new(runtime, nil, @module)
      
      # Special case: The super of Object's singleton class is Class
      @object.singleton_class.super = @class
      
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
