# Evaluates a sexp within the given scope. This file sets up some helper methods, and
# +frame_evaluation.rb+ contains all the evaluation logic.
class Carat::Runtime
  class Frame
    attr_reader :stack, :sexp, :scope
    
    extend Forwardable
    def_delegators :stack, :runtime
    def_delegators :runtime, :constants
    
    def initialize(stack, sexp, scope)
      @stack, @sexp, @scope = stack, sexp, scope
    end
    
    def sexp_type
      sexp && sexp.first
    end
    
    def sexp_body
      sexp[1..-1]
    end
    
    # Evaluate this frame
    def eval
      return nil if sexp_type.nil?
      
      if respond_to?("eval_#{sexp_type}")
        send("eval_#{sexp_type}", *sexp_body)
      else
        raise Carat::CaratError, "'#{sexp_type}' not implemented"
      end
    end
    
    # Execute a sexp on the stack. Either use the given scope, or the current scope otherwise.
    def execute(sexp_or_object, scope = nil)
      if sexp_or_object.is_a?(Carat::Data::ObjectInstance)
        sexp_or_object # We have an immediate value, no need to evaluate it
      else
        stack.execute(sexp_or_object, scope || self.scope)
      end
    end
    
    require Carat::RUNTIME_PATH + "/frame_evaluation"
  end
end
