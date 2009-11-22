# Evaluates a sexp within the given scope. This file sets up some helper methods, and
# +frame_evaluation.rb+ contains all the evaluation logic.
class Carat::Runtime
  class Frame
    attr_reader :sexp, :scope
    
    extend Forwardable
    def_delegators :scope, :runtime, :constants, :symbols
    
    class << self
      def eval(node_type, &block)
        define_method("eval_#{node_type}", &block)
      end
    end
    
    def initialize(sexp, scope)
      @sexp, @scope = sexp, scope
    end
    
    def sexp_type
      sexp.first
    end
    
    def sexp_body
      sexp[1..-1]
    end
    
    def error(message)
      raise Carat::CaratError, message
    end
    
    # Theoretically a frame can exist independently of a stack, but when we are executing the
    # frame we need a reference to the stack so that we can add new frames to it.
    def execute(stack)
      return nil if sexp_type.nil?
      return sexp unless sexp_type.is_a?(Symbol) # We assume it is already evaluated
      
      @stack = stack
      if respond_to?("eval_#{sexp_type}")
        send("eval_#{sexp_type}", *sexp_body)
      else
        error "'#{sexp_type}' not implemented"
      end
    ensure
      @stack = nil
    end
    
    # Creates a new frame for the sexp and scope, and adds it to the current stack. If scope is
    # not given, it will default to the current scope.
    def eval(sexp, scope = nil)
      @stack << Frame.new(sexp, scope || self.scope) unless sexp.nil?
    end
    
    # Converts an object in the metalanguage to a representative object in the object language. For
    # example, an Array would be converted into a Carat::Runtime::Object with
    # klass = constants[:Array]
    #
    # It makes a lot of the code more succinct, as there is (or will be, in a complete implementation)
    # a 1-1 map between classes in the metalanguage and classes in the object language
    def meta_convert(object)
      case object
        when Carat::Runtime::ObjectInstance # No need to convert
          object
        when Fixnum
          constants[:Fixnum].get(object)
        when Array
          constants[:Array].call(:new, object)
        when NilClass, String # TODO
          object
        else
          raise Carat::CaratError, "unable to meta convert #{object.inspect}"
      end
    end
    
    require Carat::RUNTIME_PATH + "/frame_evaluation"
  end
end
