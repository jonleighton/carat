# Required at the end of +frame.rb+. Just keeps all the evaluation logic solely in on file, separate
# from the various helper methods defined on +Frame+.

class Carat::Runtime
  class Frame
    eval(:false) { false }
    eval(:true) { true }
    eval(:nil) { nil }
    
    # A literal number value. This is evaluated by the lexer, so we can just use it straight off.
    eval :lit do |value|
      value
    end
    
    # A block of statements. Evaluate each in turn and return the result of the last one.
    eval :block do |*statements|
      statements.reduce(nil) { |last_result, statement| stack_eval(statement) }
    end
    
    # Make an assignment
    eval :lasgn do |identifier, value|
      scope[identifier] = stack_eval(value)
    end
    
    # Get a variable
    eval :lvar do |identifier|
      scope[identifier]
    end
    
    # call a method or retrieve a local variable. Unfortunately the sexp does not differentiate
    # between "foo" and "foo()". There is a difference - the second can only be a method call, but
    # the first might be a method call or a local variable lookup.
    eval :call do |receiver, method_name, args|
      if receiver.nil? && stack_eval(args).nil?
        value = scope[method_name]
        if false # should be "if value is a method"
          raise Carat::CaratError, "not implemented"
        else
          value
        end
      else
        object = stack_eval(receiver)
        
        if method_name == :new # Temporary special case
          new_object(object, args)
        else
          call_callable(object, method_name, args)
        end
      end
    end
    
    def new_object(klass, args)
      object = Object.new(klass)
      call_callable(object, :initialize, args)
      object
    end
    
    def call_callable(object, name, args = [])
      callable = object.lookup_method(name)
      args     = stack_eval(args)
      
      case callable
        when Method
          apply(object, callable, args)
        when Primitive
          callable.definition.call(*args)
      end
    end
    
    # Apply a list of arguments to a method
    def apply(object, method, args)
      # Create up a new scope, where the object receiving the method call is 'self'
      scope = Scope.new(object, scope)
      
      # Extend the scope, assigning all the argument values to the argument names of the method
      scope.merge! Hash[*method.args.zip(args).flatten]
      
      # Now evaluate the method contents in our new scope
      stack_eval(method.contents, scope)
    end
    
    # A list of identifiers for the arguments of a method when it is being defined
    eval :args do |*identifiers|
      identifiers
    end
    
    # A list of expressions being past as arguments to a method
    eval :arglist do |*expressions|
      expressions.map { |expression| stack_eval(expression) }
    end
    
    eval :class do |class_name, superclass, contents|
      klass = Class.new(class_name, superclass)
      scope.constants[class_name] = klass
      stack_eval(contents, Scope.new(klass, scope))
    end
    
    eval :scope do |*statement|
      # AFAIK :scope will either have 0 or 1 arguments. But if it has 0, we will get "warning: 
      # multiple values for a block parameter (0 for 1)" from MRI. So we use a splat to get around
      # that.
      statement = statement.first
      statement && stack_eval(statement)
    end
    
    eval :defn do |method_name, args, contents|
      scope[:self].methods[method_name] = Method.new(stack_eval(args), contents)
      nil
    end
    
    eval :const do |const_name|
      scope.constants[const_name]
    end
    
    eval :array do |*contents|
      new_object(scope.constants[:Array], [:arglist, *contents])
    end
  end
end
