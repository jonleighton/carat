module Carat
  # TODO: Remove when integrated with main source
  AST_DIR = File.dirname(__FILE__)

  module AST
    # ***** ABSTRACT SUPERCLASSES ****** #
    
    # The superclass of all AST nodes
    class Node
      def inspect
        self.class.to_s.sub("Carat::AST::", "")
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
        super + "[#{value.inspect}]"
      end
    end
  
    class ExpressionNode < Node
      attr_reader :expression
      
      def initialize(expression)
        @expression = expression
      end
      
      def inspect
        super + ":\n" + indent(expression.inspect)
      end
    end
    
    class NamedNode < Node
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
      
      def inspect
        super + "[#{name}]"
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
          super + ":[Empty]"
        else
          super + ":\n" + indent(items.map(&:inspect).join("\n"))
        end
      end
    end
    
    # ***** CONCRETE CLASSES ***** #
    
    require AST_DIR + "/scopes"
    require AST_DIR + "/messages"
    require AST_DIR + "/literals"
    require AST_DIR + "/variables"
  end
end
