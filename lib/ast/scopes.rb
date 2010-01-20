module Carat::AST
  class ExpressionList < NodeList
    def eval
      items.reduce(nil) { |last_result, expression| execute(expression) }
    end
  end
  
  class ModuleDefinition < Node
    attr_reader :name, :contents
    
    def initialize(name, contents)
      @name, @contents = name, contents
    end
    
    def module_object
      constants[name] ||= Carat::Data::ModuleInstance.new(runtime, name)
    end
    
    def contents_scope
      Carat::Runtime::Scope.new(module_object)
    end
    
    def eval
      execute(contents, contents_scope)
    end
    
    def inspect
      type + "[#{name}]:\n" + indent(contents.inspect)
    end
  end
  
  class ClassDefinition < Node
    attr_reader :name, :superclass, :contents
    
    def initialize(name, superclass, contents)
      @name, @superclass, @contents = name, superclass, contents
    end
    
    def superclass_object
      superclass && execute(superclass) || constants[:Object]
    end
    
    def class_object
      constants[name] ||= Carat::Data::ClassInstance.new(runtime, superclass_object, name)
    end
    
    def contents_scope
      Carat::Runtime::Scope.new(class_object)
    end
    
    def eval
      execute(contents, contents_scope)
    end
    
    def inspect
      type + "[#{name}]:\n" +
        "Superclass:\n" + indent(superclass.inspect) + "\n" +
        "Contents:\n"   + indent(contents.inspect)
    end
  end
  
  class MethodDefinition < Node
    attr_reader :receiver, :name, :argument_pattern, :contents
    
    def initialize(receiver, name, argument_pattern, contents)
      @receiver, @name, @argument_pattern, @contents = receiver, name, argument_pattern, contents
    end
    
    def current_klass
      # If the current object is not a module or class (i.e. it is a normal object), get its class
      # (this could happen, for example, if a method is defined within another method)
      if current_object.is_a?(Carat::Data::ModuleInstance)
        current_object
      else
        current_object.real_klass
      end
    end
    
    def klass
      if receiver
        # If there is a receiver this is a singleton method definition, so the method should
        # be placed in the method table of the singleton class of the receiver
        execute(receiver).singleton_class
      else
        # Otherwise get the class in the current scope
        current_klass
      end
    end
    
    def method_object
      Carat::Data::MethodInstance.new(runtime, name, argument_pattern, contents)
    end
    
    # Define a method in the current scope
    def eval
      klass.method_table[name] = method_object
      nil
    end
    
    def inspect
      type + "[#{name}]:\n" +
        "Receiver:\n" + indent(receiver.inspect) + "\n" +
        argument_pattern.inspect + "\n" +
        "Contents:\n" + indent(contents.inspect)
    end
  end
  
  class ArgumentPattern < NodeList
    # TODO: This shouldn't really be a Node because it is never really evalutated on its own. It
    # should really just be a normal object which is used to store some information. However,
    # to do this I need to extract the AST printing from "inspect" methods into a separate class.
    class Item < Node
      attr_reader :name, :pattern_type, :default
      
      def initialize(name, pattern_type, default = nil)
        @name, @pattern_type, @default = name, pattern_type, default
      end
    
      def inspect
        type + "[#{name}, #{pattern_type.inspect}]" + (default && " = \n" + indent(default.inspect) || '')
      end
    end
  end
end
