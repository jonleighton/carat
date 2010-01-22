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
    attr_reader :execution_scope
    
    # The scope in which the Call was created, used for evaluating arguments
    attr_reader :caller_scope
    
    # The AST node representing the argument list, or just a flat array of pre-evalutated objects
    attr_reader :argument_list
    
    # The continuation we should pass the answer of this call to
    attr_reader :continuation
    
    attr_reader :arguments, :argument_objects, :block_from_arguments
    
    extend Forwardable
    def_delegators :callable, :argument_pattern, :contents
    def_delegators :execution_scope, :block
    
    def initialize(runtime, callable, execution_scope, argument_list, &continuation)
      raise ArgumentError, "no continuation given" unless block_given?
      
      @runtime, @callable              = runtime, callable
      @execution_scope, @argument_list = execution_scope, argument_list
      
      @continuation = continuation
      @caller_scope = runtime.current_scope
    end
    
    # Merge the arguments into the execution scope, which becomes the scope for the contents, and
    # then execute it on the stack
    def send
      eval_arguments do |arguments|
        eval_block_from_arguments do |block_from_arguments|
          execution_scope.block = block_from_arguments unless block_from_arguments.nil?
          execution_scope.merge!(arguments)
          
          previous_ast = runtime.current_ast
          runtime.current_ast = contents
          
          contents.eval_in_scope(execution_scope) do |result|
            #p contents
            #p arguments
            #p result
            runtime.current_ast = previous_ast
            continuation.call(result)
          end
        end
      end
    end
    
    # If we have anything other than an ArgumentList AST node, we assume the argument list is an 
    # array that does not need evaluating.
    def eval_argument_objects(&continuation)
      if argument_list.is_a?(Carat::AST::ArgumentList)
        argument_list.eval_in_scope(caller_scope) do |argument_objects|
          @argument_objects = argument_objects
          yield @argument_objects
        end
      else
        @argument_objects = argument_list
        yield argument_list
      end
    end
    
    # Return a hash where the argument names of this method are assigned the given values. This
    # method makes sure the "splat" is dealt with correctly
    def eval_arguments
      eval_argument_objects do |argument_objects|
        @arguments = {}
        values = argument_objects.clone
        
        argument_pattern.items.each do |item|
          @arguments[item.name] =
            case item.pattern_type
              when :splat
                runtime.constants[:Array].new(values)
              when :block_pass
                block
              else
                values.shift
            end
        end
        
        yield @arguments
      end
    end
    
    # Gets the block from the arguments. This can be one of two things:
    # 
    #   1. Carat::AST::Block - when the block has been specified literally:
    #      items.map { ... }
    #   2. Any other AST node - when the block is passed in as an expression:
    #      items.map(&block)
    def eval_block_from_arguments
      if argument_list.is_a?(Carat::AST::ArgumentList) && argument_list.block
        argument_list.block.eval_in_scope(caller_scope) do |block_from_arguments|
          @block_from_arguments = block_from_arguments
          yield block_from_arguments
        end
      else
        yield nil
      end
    end
    
    def inspect
      result = "Call[#{callable}"
      if @argument_objects
        result << ", " unless @argument_objects.empty?
        result << @argument_objects.map(&:to_s).join(', ')
      else
        result << ", <unevaluated args>"
      end
      result << "]"
      result
    end
  end
end
