class Carat::Runtime
  class Object
    attr_reader :runtime
    attr_accessor :klass
    
    def initialize(runtime, klass)
      raise Carat::CaratError, "cannot create object without a class" if klass.nil?
      @runtime, @klass = runtime, klass
      real_klass.include_bootstrap_object_modules(self)
    end
    
    # Lookup a instance method - i.e. one defined by this object's class
    def lookup_instance_method(name)
      klass.lookup_method(name)
    end
    
    # Include an extension - specific behaviour for particular instances
    def include_extensions(mod)
      puts "Including extensions #{mod} for #{self.inspect}"
      (class << self; self; end).send(:include, mod)
    end
    
    # Include some primitives and make them available by telling the class their names
    def include_primitives(mod)
      puts "Including primitives #{mod} for #{self.inspect}"
      
      # TODO: This only needs to happen once per class, I think? We can have several instances of
      # the same class, all using the same method table.
      mod.instance_methods.each do |method_name|
        klass.methods[method_name.sub(/^primitive_/, '').to_sym] = Primitive.new(method_name.to_sym)
      end
      
      (class << self; self; end).send(:include, mod)
      included_primitives << mod
    end
    
    def included_primitives
      @included_primitives ||= []
    end
    
    def instance_variables
      @instance_variables ||= {}
    end
    
    # If the class is already a singleton class then return it, otherwise create one and insert it
    # in the hierarchy in between this object and the class. Note: +Class+ creates its singleton
    # class on initialization, and the way it fits into the hierarchy is slightly different.
    def singleton_class
      if klass.is_a?(SingletonClass)
        klass
      else
        self.klass = SingletonClass.new(runtime, self, klass)
      end
    end
    
    def real_klass
      klass.is_a?(SingletonClass) ? klass && klass.real_klass : klass
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
