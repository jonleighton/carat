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
          raise CaratError, "not implemented"
        else
          value
        end
      else
        object = stack_eval(receiver)
        
        if method_name == :new
          # Temporary special case
          Object.new(object)
        else
          stack_eval(object.lookup_method(method_name).contents, Scope.new(object, scope))
        end
      end
    end
    
    eval :arglist do |*identifiers|
      identifiers
    end
    
    eval :class do |class_name, superclass, contents|
      klass = Class.new(class_name, superclass)
      scope.constants[class_name] = klass
      stack_eval(contents, Scope.new(klass, scope))
    end
    
    eval :scope do |statement|
      stack_eval(statement)
    end
    
    eval :defn do |method_name, args, contents|
      scope[:self].methods[method_name] = Method.new(args, contents)
      nil
    end
    
    eval :const do |const_name|
      scope.constants[const_name]
    end
  end
end
