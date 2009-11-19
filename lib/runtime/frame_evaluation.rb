# Required at the end of +frame.rb+. Just keeps all the evaluation logic solely in on file, separate
# from the various helper methods defined on +Frame+.

class Carat::Runtime
  class Frame
    eval(:false) { false }
    eval(:true) { true }
    eval(:nil) { nil }
    
    # A literal number value. This is evaluated by the lexer, so we can just use it straight off.
    eval :lit do |value|
      constants[:Fixnum].get(value)
    end
    
    # A block of statements. Evaluate each in turn and return the result of the last one.
    eval :block do |*statements|
      statements.reduce(nil) { |last_result, statement| eval(statement) }
    end
    
    # Make a local assignment assignment
    eval :lasgn do |identifier, value|
      scope[identifier] = eval(value)
    end
    
    # Get a local variable
    eval :lvar do |identifier|
      scope[identifier]
    end
    
    # call a method or retrieve a local variable. Unfortunately the sexp does not differentiate
    # between "foo" and "foo()". There is a difference - the second can only be a method call, but
    # the first might be a method call or a local variable lookup.
    eval :call do |receiver, method_name, args|
      if receiver.nil? && eval(args).nil?
        value = scope[method_name]
        if false # should be "if value is a method"
          raise Carat::CaratError, "not implemented"
        else
          value
        end
      else
        object   = receiver && eval(receiver) || scope[:self]
        callable = object.lookup_instance_method(method_name)
        args     = eval(args)
        
        case callable
          when Method
            call_method(object, callable, args)
          when Primitive
            call_primitive(object, callable, args)
        end
      end
    end
    
    # Apply a list of arguments to a method
    def call_method(object, method, args)
      # Create up a new scope, where the object receiving the method call is 'self'
      new_scope = Scope.new(object, scope)
      
      # Extend the scope, assigning all the argument values to the argument names of the method
      new_scope.merge! Hash[*method.args.zip(args).flatten]
      
      # Now evaluate the method contents in our new scope
      eval(method.contents, new_scope)
    end
    
    def call_primitive(object, primitive, args)
      object.send(primitive.name, *args)
    end
    
    # A list of identifiers for the arguments of a method when it is being defined
    eval :args do |*identifiers|
      identifiers
    end
    
    # A list of expressions being past as arguments to a method
    eval :arglist do |*expressions|
      expressions.map { |expression| eval(expression) }
    end
    
    def new_module(name)
      Module.new(runtime, name)
    end
    
    eval :module do |module_name, contents|
      constants[module_name] ||= new_module(module_name)
      eval(contents, Scope.new(constants[module_name], scope))
    end
    
    def new_class(superclass, name)
      Class.new(runtime, eval(superclass) || constants[:Object], name)
    end
    
    eval :class do |class_name, superclass, contents|
      constants[class_name] ||= new_class(superclass, class_name)
      # TODO: Add code s.t. scope.extend(klass, :foo => :bar) works
      eval(contents, Scope.new(constants[class_name], scope))
    end
    
    eval :sclass do |object, contents|
      eval(contents, Scope.new(eval(object).singleton_class, scope))
    end
    
    eval :scope do |*statement|
      # AFAIK :scope will either have 0 or 1 arguments. But if it has 0, we will get "warning: 
      # multiple values for a block parameter (0 for 1)" from MRI. So we use a splat to get around
      # that.
      statement = statement.first
      statement && eval(statement)
    end
    
    # Define a method on a given class. +klass+ should be any instance of +Carat::Runtime::Class+.
    def define_method(klass, method_name, args, contents)
      klass.methods[method_name] = Method.new(eval(args), contents)
      nil
    end
    
    # Define a method in the current scope
    eval :defn do |method_name, args, contents|
      define_method(scope[:self], method_name, args, contents)
    end
    
    # Define a singleton method (by defining a method on the object's singleton class)
    eval :defs do |object, method_name, args, contents|
      define_method(eval(object).singleton_class, method_name, args, contents)
    end
    
    eval :const do |const_name|
      constants[const_name]
    end
    
    eval :array do |*contents|
      new_instance(constants[:Array], [:arglist, *contents])
    end
    
    eval :self do
      scope[:self]
    end
  end
end
