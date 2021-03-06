module Carat::Data
  class ObjectClass < ClassInstance
    def new
      ObjectInstance.new(runtime, self)
    end
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
    
    attr_reader :runtime, :carat_object_id, :instance_variables
    attr_accessor :klass
    
    extend Forwardable
    def_delegators :runtime, :constants, :stack, :current_location, :current_failure_continuation,
                   :current_call, :current_scope, :current_object, :call_stack
    
    def initialize(runtime, klass)
      @runtime, @klass    = runtime, klass
      @carat_object_id    = ObjectInstance.next_object_id
      @instance_variables = {}
    end
    
    # Lookup a instance method - i.e. one defined by this object's class
    def lookup_instance_method(name)
      klass.lookup_method(name)
    end
    
    # Lookup an intance method or raise an exception
    def lookup_instance_method!(name)
      lookup_instance_method(name) || raise(Carat::CaratError, "undefined method '#{name}'")
    end
    
    def has_instance_method?(name)
      lookup_instance_method(name) != nil
    end
    
    # Call the method with a given name, with the given argument list (AST::ArgumentList or Array).
    # This should only be called when we know the method exists. If the method does not exist an
    # exception will be raised.
    def call(method_or_name, argument_list = [], location = current_location, &continuation)
      if method_or_name.is_a?(Symbol)
        method = lookup_instance_method!(method_or_name)
      else
        method = method_or_name
      end
      
      create_call(method, argument_list, location, continuation).send
    end
    
    def singleton_class
      klass && klass.singleton? ? klass : create_singleton_class
    end
    
    # A 'real class' is the first one in the ancestry of the actual class, which is not a singleton
    def real_klass
      if klass
        real_klass = klass
        
        while real_klass && real_klass.singleton?
          real_klass = real_klass.superclass
        end
        
        real_klass
      end
    end
    
    def false_or_nil?
      instance_of?(FalseClassInstance) || instance_of?(NilClassInstance)
    end
    
    def to_s
      inspect
    end
    
    def inspect
      "<object:#{klass}>"
    end
    
    private
    
      def create_call(method, argument_list, location, continuation)
        Carat::Runtime::Call.new(
          runtime, method, argument_list,
          continuation, method_scope, location
        )
      end
      
      # A scope for evaluating the method call, with this object as 'self'
      def method_scope
        Carat::Runtime::Scope.new(self)
      end
      
      def create_singleton_class
        self.klass = constants[:SingletonClass].new(self, klass)
      end
    
    public
    
    # ***** Primitives ***** #
    
    def primitive_equal_to(other)
      if carat_object_id == other.carat_object_id
        yield runtime.true
      else
        yield runtime.false
      end
    end
    
    def primitive_object_id
      yield constants[:Fixnum].get(carat_object_id)
    end
    
    def primitive_class
      yield real_klass
    end
  end
end
