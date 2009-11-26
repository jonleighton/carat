module Carat::Data
  class ObjectClass < ClassInstance
  end

  class ObjectInstance
    attr_reader :runtime
    attr_accessor :klass
    
    extend Forwardable
    def_delegators :runtime, :current_scope, :eval, :meta_convert, :stack
    
    # All objects can have primitives
    extend PrimitiveHost
    
    def initialize(runtime, klass)
      if klass.nil? && runtime.initialized?
        raise Carat::CaratError, "cannot create object without a class"
      end
      
      @runtime, @klass = runtime, klass
    end
    
    # Lookup a instance method - i.e. one defined by this object's class
    def lookup_instance_method(name)
      klass.lookup_method(name)
    end
    
    def lookup_instance_method!(name)
      lookup_instance_method(name) || raise(Carat::CaratError, "method '#{self}##{name}' not found")
    end
    
    def call(method_name, args = [], block = nil)
      # Look up the method or primitive
      callable = lookup_instance_method!(method_name)
      
      # Create a new scope in which to evaluate the arguments and method body. Assign the block
      # to the scope if there is one.
      scope = current_scope.extend(:self => self)
      scope.block = block
      
      # Evaluate the arguments, unless they are given already evaluated. This may also assign a
      # block, if the block-as-argument syntax is used.
      args = eval(args, scope) if args.first == :arglist
      
      # Run the actual method or primitive
      case callable
        when Method
          call_method(scope, callable, args)
        when Primitive
          call_primitive(scope, callable, args)
      end
    end
    
    def call_method(scope, method, args)
      scope.merge!(method.assign_args(args, scope.block))
      eval(method.contents, scope)
    end
    
    # The frame will not actually be executed, but it holds the scope which applies when
    # we execute the primitive. Ideally a frame would take a sexp OR perhaps a block
    # or something, which would represent what we are "executing".
    def call_primitive(scope, primitive, args)
      stack << Carat::Runtime::Frame.new(nil, scope)
      result = meta_convert(send(primitive.name, *args))
      stack.pop # Don't need the frame any more
      result
    end
    
    def instance_variables
      @instance_variables ||= {}
    end
    
    # If the class is already a singleton class then return it, otherwise create one and insert it
    # in the hierarchy in between this object and the class. Note: +Class+ creates its singleton
    # class on initialization, and the way it fits into the hierarchy is slightly different.
    def singleton_class
      if klass.singleton?
        klass
      else
        self.klass = SingletonClassInstance.new(runtime, self, klass)
      end
    end
    
    def real_klass
      if klass
        klass.singleton? ? klass.real_klass : klass
      end
    end
    
    def to_s
      "<object:#{klass}>"
    end
    
    def inspect
      "<#{self.class}:(#{object_id}) " +
      ":klass=#{real_klass} " + 
      ":instance_variables=#{instance_variables.inspect} " +
      ":to_s=#{to_s}>"
    end
  end
end
