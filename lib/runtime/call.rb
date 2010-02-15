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
  # scope, evaluating the contents of the lambda/method.
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
    
    # Location that the call was made
    attr_reader :location
    
    attr_reader :arguments, :argument_objects, :block_from_arguments, :continuation
    
    extend Forwardable
    def_delegators :callable, :argument_pattern, :contents
    def_delegators :execution_scope, :block
    
    def initialize(runtime, location, callable, execution_scope, argument_list, &continuation)
      @runtime, @location, @callable   = runtime, location, callable
      @execution_scope, @argument_list = execution_scope, argument_list
      
      @continuation = continuation
      @caller_scope = runtime.current_scope
    end
    
    # Merge the arguments into the execution scope, which becomes the scope for the contents, and
    # then evaluate it
    def send
      apply_arguments do
        if contents.nil?
          continuation.call(runtime.nil)
        else
          lambda do
            frame = Frame.new(execution_scope, self)
            contents.eval_in_frame(frame, &continuation)
          end
        end
      end
    end
    
    def apply_arguments(&continuation)
      eval_block_from_arguments do |block_from_arguments|
        execution_scope.block = block_from_arguments unless block_from_arguments.nil?
        
        eval_arguments do |arguments|
          execution_scope.merge!(arguments)
          yield
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
    
    # Return a hash where the argument names of this method are assigned the given values
    def eval_arguments(&continuation)
      eval_argument_objects do |argument_objects|
        argument_pattern.match_to(argument_objects.clone, block) do |arguments|
          @arguments = arguments
          yield @arguments
        end
      end
    end
    
    # Gets the block from the arguments. This can be one of two things:
    # 
    #   1. Carat::AST::Block - when the block has been specified literally:
    #      items.map { ... }
    #   2. Any other AST node - when the block is passed in as an expression:
    #      items.map(&block)
    def eval_block_from_arguments(&continuation)
      if argument_list.is_a?(Carat::AST::ArgumentList) && argument_list.block
        argument_list.block.eval_in_scope(caller_scope) do |block_from_arguments|
          @block_from_arguments = block_from_arguments
          yield block_from_arguments
        end
      else
        yield nil
      end
    end
    
    def to_s
      callable.to_s
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
  
  class MainMethodCall
    attr_reader :location
    
    def initialize(location)
      @location = location
    end
    
    def to_s
      "main"
    end
    
    def inspect
      "Call[main]"
    end
  end
end
