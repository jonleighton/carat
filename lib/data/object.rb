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
    def_delegators :runtime, :current_node, :current_call, :current_scope, :current_object,
                             :constants, :execute, :call_stack, :execution_stack
    
    include KernelModule
    
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
    
    def has_instance_method?(name)
      lookup_instance_method(name) && true || false
    end
    
    def empty_argument_list
      argument_list = Carat::AST::ArgumentList.new
      argument_list.runtime = runtime
      argument_list
    end
    
    # Call the method with a given name, with the given AST argument list
    def call(method_name, argument_list = nil, &continuation)
      method = lookup_instance_method!(method_name)
      runtime.call(method, method_scope, argument_list || empty_argument_list, &continuation)
    end
    
    # A scope for evaluating the method call, with this object as 'self'
    def method_scope
      Carat::Runtime::Scope.new(self)
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
      if carat_object_id == other.carat_object_id
        runtime.true
      else
        runtime.false
      end
    end
    
    def primitive_object_id
      constants[:Fixnum].get(carat_object_id)
    end
  end
end
