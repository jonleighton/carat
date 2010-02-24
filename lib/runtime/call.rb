class Carat::Runtime
  class Arguments
    attr_accessor :values, :block
    
    def initialize(values = [], block = nil)
      @values, @block = values, block
    end
    
    # Assumes the last item in the array is a block or NilClassInstance representing no block
    def self.from_a(arguments)
      block = arguments.pop
      block = nil if block.is_a?(Carat::Data::NilClassInstance)
      new(arguments, block)
    end
    
    def to_a
      (@values + [block]).compact
    end
  end
  
  class AbstractCall
    # The runtime in which the call is happening
    attr_reader :runtime
    
    # The object representing whatever we are calling (method, lambda, primitive method, etc)
    attr_reader :callable
    
    # The scope in which the Call was created, used for evaluating arguments
    attr_reader :caller_scope
    
    # The argument list can come in various forms, see eval_arguments
    attr_reader :argument_list
    
    # The continuation of this call - i.e. the computation to be done afterwards
    attr_reader :continuation
    
    def initialize(runtime, callable, argument_list, continuation)
      @caller_scope = runtime.current_scope
      
      @runtime,       @callable     = runtime,       callable
      @argument_list, @continuation = argument_list, continuation
    end
    
    def send
      raise NotImplementedError
    end
    
    private
    
      # This method returns an Arguments object. Before "evaluation" the arguments may be one of
      # three things:
      # 
      #   1. An Arguments object; just yield immediately
      #   2. An Array; pass to a new Arguments object and yield
      #   3. An ArgumentList AST node; evaluate it
      def eval_arguments(&continuation)
        case argument_list
          when Arguments
            yield argument_list
          when Array
            yield Arguments.new(argument_list)
          else
            argument_list.eval_in_scope(caller_scope, &continuation)
        end
      end
  end
  
  class PrimitiveCall < AbstractCall
    def send
      eval_arguments do |arguments|
        callable.call(*arguments.to_a, &return_continuation)
      end
    end
    
    def return_continuation
      @return_continuation ||= lambda do |result|
        unless result.is_a?(Carat::Data::ObjectInstance)
          raise Carat::CaratError, "primitive '#{name}' did not return an ObjectInstance: #{result.inspect}"
        end
        
        continuation.call(result)
      end
    end
  end
  
  class Call < AbstractCall
    # Scope used for the evaluation of the call
    attr_reader :scope
    
    # Location that the call was made at
    attr_reader :location
    
    extend Forwardable
    def_delegators :callable, :argument_pattern, :contents
    
    def initialize(runtime, callable, argument_list, continuation, scope, location)
      super(runtime, callable, argument_list, continuation)
      @scope, @location = scope, location
    end
    
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
        @frame ||= Frame.new(scope, self)
      end
      
      def apply_arguments(&continuation)
        eval_arguments do |arguments|
          scope.block = arguments.block unless arguments.block.nil?
          argument_pattern.assign(arguments.values.clone, &continuation)
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
