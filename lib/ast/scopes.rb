module Carat::AST
  class ExpressionList < NodeList
    def eval(&continuation)
      operation = lambda do |object, accumulation, node, &operation_continuation|
        operation_continuation.call(object)
      end
      
      eval_fold(runtime.nil, operation, &continuation)
    end
  end
  
  class ModuleDefinition < Node
    property :name
    child    :contents
    
    def module_object
      constants[name] ||= constants[:Module].new(name)
    end
    
    def contents_scope
      Carat::Runtime::Scope.new(module_object)
    end
    
    def eval(&continuation)
      eval_child(contents, contents_scope, &continuation)
    end
  end
  
  class ClassDefinition < Node
    property :name
    child    :superclass
    child    :contents
    
    def eval_superclass_object(&continuation)
      if superclass
        eval_child(superclass, &continuation)
      else
        yield constants[:Object]
      end
    end
    
    def eval_class_object
      eval_superclass_object do |superclass_object|
        yield constants[name] ||= constants[:Class].new(superclass_object, name)
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
  end
  
  class MethodDefinition < Node
    child    :receiver
    property :name
    child    :argument_pattern
    child    :contents
    
    def method_object
      constants[:Method].new(name, argument_pattern, contents)
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
  end
  
  class ArgumentPattern < NodeList
    class Item < Node
      child    :assignee
      property :type,    :default => :normal
      child    :default, :default => nil
      
      # A splat it considered mandatory, but it can match 0 arguments
      # A block pass is always optional and will default to nil
      def mandatory?
        type == :splat || (type == :normal && default.nil?)
      end
      
      def optional?
        !mandatory?
      end
      
      def minimum_arity
        case type
          when :splat, :block_pass
            0
          else
            default ? 0 : 1
        end
      end
      
      def maximum_arity
        case type
          when :splat
            (1.0/0) # Infinity
          when :block_pass
            0 # Block pass is not considered party of the arity
          else
            1
        end
      end
    end
    
    def minimum_arity
      items.inject(0) { |sum, item| sum + item.minimum_arity }
    end
    
    def maximum_arity
      items.inject(0) { |sum, item| sum + item.maximum_arity }
    end
    
    def arity
      @arity ||= minimum_arity..maximum_arity
    end
    
    def arity_as_string
      if minimum_arity == maximum_arity
        minimum_arity.to_s
      else
        "#{minimum_arity} to #{maximum_arity}"
      end
    end
    
    def normal_items_after_splat
      items.drop_while { |item| item.type != :splat }.
        drop(1).reject { |item| item.type == :block_pass}
    end
    
    def values_for_splat(values)
      values.shift(values.length - normal_items_after_splat.length)
    end
    
    def value_for(item, values, &continuation)
      case item.type
        when :splat
          yield runtime.constants[:Array].new(values_for_splat(values))
        when :block_pass
          yield current_scope.block || runtime.nil
        else
          value = values.shift
          
          if value
            yield value
          else
            eval_child(item.default, &continuation)
          end
      end
    end
    
    def assign(values, &continuation)
      if arity.include?(values.length)
        assign_item_operation = lambda do |item, &each_continuation|
          value_for(item, values) do |value|
            item.assignee.assign(value) do
              each_continuation.call
            end
          end
        end
        
        runtime.each(assign_item_operation, items, &continuation)
      else
        runtime.raise :ArgumentError, "wrong number of arguments (#{values.length} supplied, " +
                                      "#{arity_as_string} required)"
      end
    end
  end
end
