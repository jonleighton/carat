module Carat::Data
  class ClassClass < ModuleClass
    def new(superclass, name = nil)
      ClassInstance.new(runtime, self, superclass, name)
    end
  end
  
  class ClassInstance < ModuleInstance
    def initialize(runtime, klass, superclass, name = nil)
      @super = superclass
      super(runtime, klass, name || inferred_name)
    end
    
    # The super may be an include class for a module, but we want the first ancestor which is a 
    # "proper" class
    def superclass
      if @super.is_a?(IncludeClassInstance)
        @super && @super.super
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
          if Carat::Data.const_defined?("#{name}Instance")
            Carat::Data.const_get("#{name}Instance")
          else
            Carat::Data::ObjectInstance
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
  end
end
