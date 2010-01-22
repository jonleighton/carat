module Carat
  module AST
    # ***** ABSTRACT SUPERCLASSES ****** #
    
    # The superclass of all AST nodes
    class Node
      attr_reader :runtime
      
      extend Forwardable
      def_delegators :runtime, :constants, :current_call, :current_scope, :current_object
      
      def runtime=(runtime_object)
        @runtime = runtime_object
        children.compact.each { |child| child.runtime = runtime_object }
      end
      
      # Subclasses should implement this method so that children can be manipulated
      def children
        raise NotImplementedError
      end
      
      def eval_in_scope(scope, &continuation)
        raise ArgumentError, "no continuation given" unless block_given?
        
        # Store the current scope, and then update the current scope to be the scope needed when
        # evaluating the child node
        previous_scope = current_scope
        runtime.current_scope = scope
        
        eval do |result|
          # Node has been evaluated, so reset the current scope to the previous scope before
          # passing the result on to the continuation
          runtime.current_scope = previous_scope
          yield result
        end
      end
      
      def eval_child(node, new_scope = nil, &continuation)
        if node.nil?
          yield runtime.nil
        else
          node.eval_in_scope(new_scope || current_scope, &continuation)
        end
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
    
    # A node which has a given single value when evaluated
    class ValueNode < Node
      def value_object
        raise NotImplementedError
      end
      
      def children
        []
      end
      
      def eval
        yield value_object
      end
    end
    
    # A node representing a value drawn from a set of possibilities - for example a string or
    # integer value
    class MultipleValueNode < ValueNode
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
      attr_writer :runtime
      
      def initialize(name)
        @name = name
      end
      
      def children
        []
      end
      
      def inspect
        type + "[#{name}]"
      end
    end
    
    class NodeList < Node
      attr_reader :items
      
      alias_method :children, :items
      
      def initialize(items = [])
        @items = items
      end
      
      def empty?
        items.empty?
      end
      
      # Fold the items by evaluating each one in turn and then passing the evaluated object to an
      # operation function
      def eval_fold(base, operation, items = self.items, &continuation)
        fold_operation = lambda do |node, accumulation, &inner_continuation|
          eval_child(node) do |object|
            inner_continuation.call operation.call(object, accumulation, node)
          end
        end
        
        runtime.fold(base, fold_operation, items, &continuation)
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
