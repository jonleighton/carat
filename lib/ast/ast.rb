module Carat
  module AST
    require AST_PATH + "/printer"
    
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
        
        def properties
          attributes.find_all { |attribute| attribute[:type] == :property }
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
      def_delegators :runtime, :constants, :stack, :current_object, :current_location,
                               :current_scope, :current_failure_continuation
      
      def initialize(location = nil, *attributes)
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
        eval_in_frame(Carat::Runtime::Frame.new(scope), &continuation)
      end
      
      def eval_with_failure_continuation(failure_continuation, &continuation)
        eval_in_frame(Carat::Runtime::Frame.new(nil, nil, failure_continuation), &continuation)
      end
      
      def eval_in_frame(frame, &continuation)
        stack << frame
        
        eval do |result|
          stack.pop
          yield result
        end
      end
      
      def eval_child(node, scope_or_failure_continuation = nil, &continuation)
        if node.nil?
          yield runtime.nil
        else
          if scope_or_failure_continuation
            case scope_or_failure_continuation
              when Carat::Runtime::Scope
                node.eval_in_scope(scope_or_failure_continuation, &continuation)
              when Proc
                node.eval_with_failure_continuation(scope_or_failure_continuation, &continuation)
            end
          else
            node.eval(&continuation)
          end
        end
      end
      
      def eval
        raise CaratError, "evaluation logic for #{self} not implemented"
      end
      
      def inspect
        Printer.new.print(self)
      end
      
      def to_ast
        self
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
    end
    
    class NamedNode < Node
      property :name
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
    end
    
    class BinaryNode < Node
      child :left
      child :right
    end
    
    # ***** CONCRETE CLASSES ***** #
    
    require AST_PATH + "/scopes"
    require AST_PATH + "/messages"
    require AST_PATH + "/literals"
    require AST_PATH + "/variables"
    require AST_PATH + "/control"
  end
end
