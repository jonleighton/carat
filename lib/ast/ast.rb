module Carat
  module AST
    # ***** ABSTRACT SUPERCLASSES ****** #
    
    # The superclass of all AST nodes
    class Node
      attr_reader :runtime, :scope
      
      extend Forwardable
      def_delegators :runtime, :constants, :current_call
      
      # TODO: Nodes shouldn't really hold the scope, as this can change when they are evaluated at
      #       different times. It would be better if the runtime held the scope. [Is this really 
      #       true? Is there a case where the runtime scope might change but the previous scope
      #       should be retained?]
      def eval_in_runtime(runtime, scope, &continuation)
        raise Carat::CaratError, "no continuation given" unless block_given?
        @runtime = runtime
        @scope = scope
        eval(&continuation)
      ensure
        @runtime = @scope = nil
      end
      
      def eval_child(node, scope = nil, &continuation)
        raise Carat::CaratError, "no continuation given" unless block_given?
        node.eval_in_runtime(runtime, scope || self.scope, &continuation)
      end
      
      def current_object
        scope[:self]
      end
      
      def eval
        raise CaratError, "evaluation logic for #{type} not implemented"
      end
      
      def type
        self.class.to_s.sub("Carat::AST::", "")
      end
      
      def inspect
        type
      end
      
      def to_ast
        self
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
      
      # This is similar to a 'foldr' or 'inject' function, but written for this specific context
      # where we are using continuation passing style
      def fold(nodes, base, operation, &continuation)
        if nodes.empty?
          yield base
        else
          node = nodes.first
          eval_child(node) do |object|
            fold(nodes.drop(1), base, operation) do |accumulation|
              yield operation.call(object, accumulation, node)
            end
          end
        end
      end
      
      # Evaluate each item in the array and return a new array with the answers
      def eval_array(nodes, &continuation)
        append = Proc.new { |object, accumulation| accumulation << object }
        fold(nodes, [], append, &continuation)
      end
      
      def inspect
        if empty?
          type + ":\n" + indent("[Empty]")
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
    require AST_PATH + "/control"
  end
end
