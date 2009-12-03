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
    
    # A node representing the definition of "something" - for example a class or a method
    class DefinitionNode < Node
      attr_reader :name, :contents
      
      def initialize(name, contents)
        @name, @contents = name, contents
      end
      
      def inspect
        super + "[#{name}]:\n" + indent(contents.inspect)
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
    
    class NamedNode < Node
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
      
      def inspect
        super + "[#{name}]"
      end
    end
    
    # ***** CONCRETE CLASSES ***** #
    
    require AST_DIR + "/block"
    require AST_DIR + "/class_definition"
    require AST_DIR + "/method_definition"
    require AST_DIR + "/method_call"
    require AST_DIR + "/literals"
    require AST_DIR + "/variables"
  end
end
