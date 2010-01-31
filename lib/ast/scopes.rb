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
    child    :receiver
    property :name
    child    :argument_pattern
    child    :contents
    
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
    class Item < Node
      property :name
      property :pattern_type
      child    :default, :default => nil
      
      def value(values, block, &continuation)
        case pattern_type
          when :splat
            yield runtime.constants[:Array].new(values)
          when :block_pass
            yield block || runtime.nil
          else
            value = values.shift
            if value
              yield value
            elsif default
              eval_child(default, &continuation)
            else
              yield runtime.nil
            end
        end
      end
      
      def inspect
        type + "[#{name}, #{pattern_type.inspect}]" + (default && " = \n" + indent(default.inspect) || '')
      end
    end
    
    def match_to(values, block, &continuation)
      match_operation = lambda do |item, arguments, &match_continuation|
        item.value(values, block) do |value|
          arguments[item.name] = value
          match_continuation.call(arguments)
        end
      end
      
      runtime.fold({}, match_operation, items, &continuation)
    end
  end
end
