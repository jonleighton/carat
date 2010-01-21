module Carat::AST
  class ExpressionList < NodeList
    def eval(&continuation)
      operation = lambda { |object, accumulation, node| object }
      fold(items, runtime.nil, operation, &continuation)
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
    
    def eval(&continuation)
      eval_child(contents, contents_scope, &continuation)
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
    
    def eval_superclass_object(&continuation)
      if superclass
        eval_child(superclass, &continuation)
      else
        yield constants[:Object]
      end
    end
    
    def eval_class_object
      eval_superclass_object do |superclass_object|
        yield constants[name] ||= Carat::Data::ClassInstance.new(runtime, superclass_object, name)
      end
    end
    
    def eval_contents_scope
      eval_class_object do |class_object|
        yield Carat::Runtime::Scope.new(class_object)
      end
    end
    
    def eval(&continuation)
      eval_contents_scope do |contents_scope|
        eval_child(contents, contents_scope, &continuation)
      end
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
    
    def method_object
      Carat::Data::MethodInstance.new(runtime, name, argument_pattern, contents)
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
    
    def eval_klass(&continuation)
      if receiver
        # If there is a receiver this is a singleton method definition, so the method should
        # be placed in the method table of the singleton class of the receiver
        eval_child(receiver) do |receiver_object|
          yield receiver_object.singleton_class
        end
      else
        # Otherwise get the class in the current scope
        yield current_klass
      end
    end
    
    # Define a method in the current scope
    def eval
      eval_klass do |klass|
        klass.method_table[name] = method_object
        yield runtime.nil
      end
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