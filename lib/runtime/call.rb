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
  class Call
    class Arguments
      attr_accessor :values, :block
      
      def initialize(values = [], block = nil)
        @values, @block = values, block
      end
    end
    
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
    
    # The continuation of this call - i.e. the computation to be done afterwards
    attr_reader :continuation
    
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
      runtime.stack << frame
      apply_arguments do
        if contents.nil?
          return_continuation.call(runtime.nil)
        else
          lambda { contents.eval(&return_continuation) }
        end
      end
    end
    
    def return_continuation
      @return_continuation ||= lambda do |result|
        runtime.stack.pop
        continuation.call(result)
      end
    end
    
    def to_s
      callable.to_s
    end
    
    def inspect
      "Call[#{callable}, #{location}]"
    end
    
    private
    
      def frame
        @frame ||= Frame.new(execution_scope, self)
      end
      
      def apply_arguments(&continuation)
        eval_arguments do |arguments|
          execution_scope.block = arguments.block unless arguments.block.nil?
          argument_pattern.assign(arguments.values.clone, &continuation)
        end
      end
      
      def eval_arguments(&continuation)
        if argument_list.is_a?(Carat::AST::ArgumentList)
          argument_list.eval_in_scope(caller_scope, &continuation)
        else
          yield Arguments.new(argument_list)
        end
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
