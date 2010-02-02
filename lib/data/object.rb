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
    
    attr_reader :runtime, :carat_object_id
    attr_accessor :klass
    
    extend Forwardable
    def_delegators :runtime, :constants, :call_stack, :scope_stack, :current_return_continuation,
                   :current_call, :current_scope, :current_object, :current_failure_continuation,
                   :current_location
    
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
    def call(name, argument_list = [], location = nil, &continuation)
      method = lookup_instance_method!(name)
      runtime.call(location, method, method_scope, argument_list, &continuation)
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
    
    def false_or_nil?
      false
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
