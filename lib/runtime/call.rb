class Carat::Runtime
  # Unified interface for calling both methods and lambdas. They vary in that:
  # 
  #   * Lambdas store the scope in which they were created, and use this scope when called
  #   * Methods don't store a scope. Their scope is created when they are called, with the receiver
  #     of the call being assigned to 'self'
  # 
  # However, they both have identical semantics for evaluating an argument list, and this is done
  # within the "caller scope" - the scope in which the call was made.
  # 
  # Therefore when a Call instance is created, we take as an argument the scope which the callable
  # should be executed within, but take care of evaluating arguments and assigning them to this
  # scope, before pushing the method/lambda contents on the stack.
  # 
  # TODO: It is my intention to add the functionality for methods to be converted to lambdas (with
  # an empty scope) and for lambdas to be able to dynamically change their scope.
  class Call
    # The runtime in which the call is happening
    attr_reader :runtime
    
    # Callable object - either a method or a lambda
    attr_reader :callable
    
    # The scope in which the arguments should be assigned, and the contents of the callable should
    # be executed
    attr_reader :scope
    
    # The AST node representing the argument list, or just a flat array of pre-evalutated objects
    attr_reader :argument_list
    
    extend Forwardable
    def_delegators :callable, :argument_pattern, :contents
    def_delegators :runtime, :current_node
    
    def initialize(runtime, callable, scope, argument_list)
      @runtime, @callable    = runtime, callable
      @scope, @argument_list = scope, argument_list
    end
    
    # Merge the arguments into the execution scope, which becomes the scope for the contents, and
    # then execute it on the stack
    def send
      scope.merge!(arguments)
      current_node.execute(contents, scope)
    end
    
    # If we have anything other than an ArgumentList AST node, we assume the argument list is an 
    # array that does not need evaluating.
    def argument_objects
      @argument_objects ||= begin
        if argument_list.is_a?(Carat::AST::ArgumentList)
          current_node.execute(argument_list)
        else
          argument_list
        end
      end
    end
    
    # Return a hash where the argument names of this method are assigned the given values. This
    # method makes sure the "splat" is dealt with correctly
    # TODO: Deal with blocks
    # TODO: Splat is broken because it creates a Ruby array, not a Carat array object
    def arguments
      @arguments ||= begin
        result = {}
        
        values = argument_objects.clone
        argument_pattern.items.each do |item|
          case item
            when Carat::AST::ArgumentPatternItem
              result[item.name] = values.shift
            when Carat::AST::SplatArgumentPatternItem
              result[item.name] = values
          end
        end
        
        result
      end
    end
  end
end
