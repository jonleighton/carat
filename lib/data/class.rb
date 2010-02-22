module Carat::Data
  class ClassClass < ModuleClass
    def new(superclass, name = nil)
      ClassInstance.new(runtime, self, superclass, name)
    end
  end
  
  class ClassInstance < ModuleInstance
    attr_accessor :super
    
    def initialize(runtime, klass, superclass, name = nil)
      @super = superclass
      super(runtime, klass, name || inferred_name)
    end
    
    def lookup_method(name)
      method_table[name] || (@super && @super.lookup_method(name))
    end
    
    def ancestors
      if @super
        [self] + @super.ancestors
      else
        [self]
      end
    end
    
    # The super may be an include class, so we want the first ancestor which is a "proper" class
    def superclass
      if @super.is_a?(IncludeClassInstance)
        @super && @super.superclass
      else
        @super
      end
    end
    
    def to_s
      "<class:#{name}>"
    end
    
    private
    
      def create_singleton_class
        if constants[:SingletonClass]
          self.klass = constants[:SingletonClass].new(self, superclass && superclass.singleton_class)
        end
      end
      
      # The inferred name is the name of the class in the object language, taken from the name of the
      # class representing it in the implementation language. For instance, if this is an instance of
      # +FixnumClass+, then the inferred name is +:Fixnum+
      def inferred_name
        @inferred_name ||= begin
          # We must be in a subclass of ClassInstance in order to infer a name
          unless instance_of?(ClassInstance)
            self.class.to_s.sub(/^.*\:\:/, '').sub(/Class$/, '').to_sym
          end
        end
      end
      
      # Returns the class which is used to represent an instance of this class.
      # 
      # For example, if this class is +FixnumClass+, the +instance_class+ will be +FixnumInstance+
      def instance_class
        @instance_class ||= begin
          ancestors.each do |ancestor|
            if Carat::Data.const_defined?("#{ancestor.name}Instance")
              return Carat::Data.const_get("#{ancestor.name}Instance")
            end
          end
        end
      end
    
    public
    
    # ***** Primitives ***** #
    
    def primitive_allocate
      yield instance_class.new(runtime, self)
    end
    
    def primitive_superclass
      yield superclass || runtime.nil
    end
    
    def primitive_include(mod)
      @super = IncludeClassInstance.new(runtime, mod, @super)
      instance_class.send(:include, mod.primitives_module) if mod.primitives_module
      yield mod
    end
  end
end
