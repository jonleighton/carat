module Carat
  module AST
    # ***** ABSTRACT SUPERCLASSES ****** #
    
    # The superclass of all AST nodes
    class Node
      attr_accessor :scope
      attr_reader :runtime
      
      extend Forwardable
      def_delegators :runtime, :stack, :constants
      
      def eval_in_runtime(runtime)
        @runtime = runtime
        raise CaratError, "scope not set" if scope.nil?
        eval
      end
      
      def eval
        raise CaratError, "evaluation logic for #{type} not implemented"
      end
      
      # Execute a node on the stack. Either use the given scope, or this node's scope otherwise.
      def execute(node_or_object, scope = nil)
        return nil if node_or_object.nil?
        
        if node_or_object.is_a?(Carat::Data::ObjectInstance)
          node_or_object # We have an immediate value, no need to evaluate it
        else
          node_or_object.scope = scope || self.scope
          stack.execute(node_or_object)
        end
      end
      
      def type
        self.class.to_s.sub("Carat::AST::", "")
      end
      
      def inspect
        type
      end
      
      protected
      
        def indent(text)
          "  " + text.gsub("\n", "\n  ")
        end
    end
    
    # A node representing a value - for example a string or integer value
    class ValueNode < Node
      attr_reader :value
      
      def initialize(value)
        @value = value
      end
      
      def inspect
        type + "[#{value.inspect}]"
      end
    end
  
    class ExpressionNode < Node
      attr_reader :expression
      
      def initialize(expression)
        @expression = expression
      end
      
      def inspect
        type + ":\n" + indent(expression.inspect)
      end
    end
    
    class NamedNode < Node
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
      
      def inspect
        type + "[#{name}]"
      end
    end
    
    class NodeList < Node
      attr_reader :items
      
      def initialize(items = [])
        @items = items
      end
      
      def empty?
        items.empty?
      end
      
      def inspect
        if empty?
          type + ":[Empty]"
        else
          type + ":\n" + indent(items.map(&:inspect).join("\n"))
        end
      end
    end
    
    # ***** CONCRETE CLASSES ***** #
    
    require AST_PATH + "/scopes"
    require AST_PATH + "/messages"
    require AST_PATH + "/literals"
    require AST_PATH + "/variables"
  end
end
