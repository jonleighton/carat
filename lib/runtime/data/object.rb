class Carat::Runtime
  class ObjectClass < ClassInstance
  end

  class ObjectInstance
    attr_reader :runtime
    attr_accessor :klass
    
    extend Forwardable
    def_delegators :runtime, :current_scope, :eval, :meta_convert
    
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
    
    def call(method_name, args = [])
      callable = lookup_instance_method!(method_name)
      args = eval(args) if args.first == :arglist
      
      case callable
        when Method
          call_method(callable, args)
        when Primitive
          call_primitive(callable, args)
      end
    end
    
    def call_method(method, args)
      # Create up a new scope, where the object receiving the method call is 'self'
      new_scope = Scope.new(self, current_scope)
      
      # Extend the scope, assigning all the argument values to the argument names of the method
      new_scope.merge!(method.assign_args(args))
      
      # Now evaluate the method contents in our new scope
      eval(method.contents, new_scope)
    end
    
    def call_primitive(primitive, args)
      meta_convert(send(primitive.name, *args))
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
