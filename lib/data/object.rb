module Carat::Data
  class ObjectClass < ClassInstance
  end

  class ObjectInstance
    class << self
      def next_object_id
        if @current_object_id
          @current_object_id += 1
        else
          @current_object_id = 1
        end
      end
    end
    
    attr_reader :runtime, :carat_object_id
    attr_accessor :klass
    
    extend Forwardable
    def_delegators :runtime, :current_node, :stack, :meta_convert
    def_delegators :current_node, :execute, :scope
    
    # All objects can have primitives
    extend PrimitiveHost
    
    def initialize(runtime, klass)
      if klass.nil? && runtime.initialized?
        raise Carat::CaratError, "cannot create object without a class"
      end
      
      @runtime, @klass = runtime, klass
      @carat_object_id = ObjectInstance.next_object_id
    end
    
    # Lookup a instance method - i.e. one defined by this object's class
    def lookup_instance_method(name)
      klass.lookup_method(name)
    end
    
    def lookup_instance_method!(name)
      lookup_instance_method(name) || raise(Carat::CaratError, "method '#{self}##{name}' not found")
    end
    
    def call(method_name, args = Carat::AST::ArgumentList.new, block = nil)
      # Look up the method or primitive
      callable = lookup_instance_method!(method_name)
      
      # We want the arguments to be evaluated within the caller's scope. However, the arguments
      # may change the scope's block, if there is a :block_pass. We don't want this to persist
      # after the arguments are evaluated, so we create a child scope solely for evaluating the
      # arguments.
      arg_scope       = scope.extend
      arg_scope.block = scope.block
      
      # Only execute the args if they are an AST node.
      # Otherwise we assume it is an array of objects which don't need evaluation.
      args = execute(args, arg_scope) if args.is_a?(Carat::AST::ArgumentList)
      
      # Create a new scope for the method body, with self as the receiving object
      method_scope = Carat::Runtime::SymbolTable.new(:self => self)
      
      # Set the block which will be available inside the method. This is either a block passed
      # within the args, or a block which is explicitly given as an iterator.
      method_scope.block = block || arg_scope.block
      
      # Run the actual method or primitive
      case callable
        when Method
          call_method(method_scope, callable, args)
        when Primitive
          call_primitive(method_scope, callable, args)
      end
    end
    
    def call_method(scope, method, args)
      scope.merge!(method.assign_args(args, scope.block))
      result = execute(method.contents, scope)
      result
    end
    
    def call_primitive(scope, primitive, args)
      node = Carat::AST::SendMethod.new(self, primitive.name, *args)
      meta_convert(execute(node, scope))
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
    
    def instance_variables
      @instance_variables ||= {}
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
    
    # ***** PRIMITIVES ***** #
    
    def primitive_equality_op(other)
      carat_object_id == other.carat_object_id
    end
    rename_primitive :equality_op, :==
    
    def primitive_object_id
      carat_object_id
    end
  end
end
