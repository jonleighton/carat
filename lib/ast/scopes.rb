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
      unless constants.has?(name)
        constants[name] = Carat::Data::ModuleInstance.new(runtime, name)
      end
      
      constants[name]
    end
    
    def contents_scope
      Carat::Runtime::SymbolTable.new(:self => module_object)
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
      unless constants.has?(name)
        constants[name] = Carat::Data::ClassInstance.new(runtime, superclass_object, name)
      end
      
      constants[name]
    end
    
    def contents_scope
      Carat::Runtime::SymbolTable.new(:self => class_object)
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
    
    def klass
      if receiver
        # If there is a receiver this is a singleton method definition, so the method should
        # be placed in the method table of the singleton class of the receiver
        execute(receiver).singleton_class
      else
        # Otherwise, if the current 'self' is not a module or class, get the class of 'self'
        # (this could happen, for example, if a method is defined within another method)
        if scope[:self].is_a?(Carat::Data::ModuleInstance)
          scope[:self]
        else
          scope[:self].real_klass
        end
      end
    end
    
    # Define a method in the current scope
    def eval
      klass.method_table[name] = Carat::Data::Method.new(argument_pattern, contents)
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
    attr_reader :block_pass
    
    def initialize(items = [], block_pass = nil)
      super(items)
      @block_pass = block_pass
    end
    
    def inspect
      super + (block_pass && "\n" + indent("Block Pass: #{block_pass}") || "")
    end
  end
  
  class ArgumentPatternItem < Node
    attr_reader :name, :default
    
    def initialize(name, default)
      @name, @default = name, default
    end
    
    def inspect
      type + "[#{name}]" + (default && " = \n" + indent(default.inspect) || '')
    end
  end
  
  class SplatArgumentPatternItem < NamedNode
  end
end
