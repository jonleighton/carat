module Carat
  module AST
    # ***** ABSTRACT SUPERCLASSES ****** #
    
    # The superclass of all AST nodes
    class Node
      class << self
        def attributes
          @attributes ||= begin
            if superclass.respond_to?(:attributes)
              superclass.attributes.clone
            else
              []
            end
          end
        end
        
        def required_attributes
          attributes.find_all { |attribute| !attribute.has_key?(:default) }
        end
        
        [:child, :children, :property].each do |attribute_type|
          class_eval <<-CODE
            def #{attribute_type}(name, options = {})
              class_eval { attr_reader name }
              attributes << options.merge(:type => :#{attribute_type}, :name => name)
            end
          CODE
        end
      end
      
      attr_reader :runtime, :location
      
      extend Forwardable
      def_delegators :runtime, :constants, :current_call, :current_scope, :current_object
      
      def initialize(location, *attributes)
        @location = location
        
        if self.class.required_attributes.length > attributes.length
          raise ArgumentError, "wrong number of attributes"
        end
        
        self.class.attributes.each do |attribute|
          instance_variable_set("@#{attribute[:name]}", attributes.shift || attribute[:default])
        end
      end
      
      def runtime=(runtime_object)
        @runtime = runtime_object
        children.compact.each { |child| child.runtime = runtime_object }
      end
      
      def children
        @children ||= self.class.attributes.inject([]) do |children, attribute|
          value = instance_variable_get("@#{attribute[:name]}")
          
          if attribute[:type] == :children
            children + value
          elsif attribute[:type] == :child
            children << value
          else
            children
          end
        end
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
      
      def eval
        yield value_object
      end
    end
    
    # A node representing a value drawn from a set of possibilities - for example a string or
    # integer value
    class MultipleValueNode < ValueNode
      property :value
      
      def inspect
        type + "[#{value.inspect}]"
      end
    end
    
    class NamedNode < Node
      property :name
      
      def inspect
        type + "[#{name}]"
      end
    end
    
    class NodeList < Node
      children :items, :default => []
      
      def empty?
        items.empty?
      end
      
      # Fold the items by evaluating each one in turn and then passing the evaluated object to an
      # operation function
      def eval_fold(base_answer, operation, items = self.items, &continuation)
        # This lambda evaluates the AST node it is passed, and then computes the next answer for the
        # fold by combining the result with the current answer, using the operation provided, which
        # then yields to the fold_continuation
        fold_operation = lambda do |node, current_answer, &fold_continuation|
          eval_child(node) do |result|
            operation.call(result, current_answer, node, &fold_continuation)
          end
        end
        
        runtime.fold(base_answer, fold_operation, items, &continuation)
      end
      
      def inspect
        if empty?
          type + ":\n" + indent("[Empty]")
        else
          type + ":\n" + indent(items.map(&:inspect).join("\n"))
        end
      end
    end
    
    class BinaryNode < Node
      child :left
      child :right
      
      def inspect
        type + ":\n" +
          "Left:\n" + indent(left.inspect) + "\n" +
          "Right:\n" + indent(right.inspect)
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
