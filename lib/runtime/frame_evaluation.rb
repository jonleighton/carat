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
    
    def assign(type, left, right)
      case type
        when :lasgn # e.g. [:lasgn, :x, [:lit, :4]]
          scope[left] = eval(right)
        when :masgn # e.g. [:masgn, [:array, [:lasgn, :x], [:splat, :y]], [:array, [:lit, 4], [:lit, 5], [:lit, 6]]]
          # left and right are initially [:array, ...]
          left.shift
          right.shift
          
          # Match up elements from the left and right
          left.each do |item|
            case item.first
              when :lasgn
                identifier = item[1]
                value = right.shift
              when :splat
                identifier = item[1][1]
                value = [:array, *right]
              else
                raise Carat::CaratError
            end
            
            assign(:lasgn, identifier, value)
          end
        else
          raise Carat::CaratError
      end
    end
    
    # Make a local assignment assignment
    eval :lasgn do |left, right|
      assign(:lasgn, left, right)
    end
    
    # Multiple assignment - e.g. x, y = 5, 2
    eval :masgn do |left, right|
      assign(:masgn, left, right)
    end
    
    # Get a local variable
    eval :lvar do |identifier|
      scope[identifier]
    end
    
    # call a method or retrieve a local variable. Unfortunately the sexp does not differentiate
    # between "foo" and "foo()". There is a difference - the second can only be a method call, but
    # the first might be a method call or a local variable lookup.
    def eval_call(receiver, method_name, args, block = nil)
      if receiver.nil? && args == [:arglist]
        # If there is no explicit receiver, and there are no arguments, we are either dealing with
        # a local variable or a method call to 'self'
        
        if scope.has?(method_name)
          scope[method_name]
        else
          scope[:self].call(method_name, args, block)
        end
      else
        object = receiver && eval(receiver) || scope[:self]
        object.call(method_name, args, block)
      end
    end
    
    # A list of identifiers for the arguments of a method when it is being defined
    eval :args do |*identifiers|
      identifiers
    end
    
    # A list of expressions being passed as arguments to a method
    eval :arglist do |*expressions|
      expressions.map { |expression| eval(expression) }
    end
    
    def new_module(name)
      Carat::Data::ModuleInstance.new(runtime, name)
    end
    
    eval :module do |module_name, contents|
      constants[module_name] ||= new_module(module_name)
      eval(contents, Scope.new(constants[module_name], scope))
    end
    
    def new_class(superclass, name)
      Carat::Data::ClassInstance.new(runtime, eval(superclass) || constants[:Object], name)
    end
    
    eval :class do |class_name, superclass, contents|
      constants[class_name] ||= new_class(superclass, class_name)
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
      klass.method_table[method_name] = Carat::Data::Method.new(eval(args), contents)
      nil
    end
    
    # Define a method in the current scope
    eval :defn do |method_name, args, contents|
      if scope[:self].is_a?(Carat::Data::ModuleInstance)
        klass = scope[:self]
      else
        klass = scope[:self].real_klass
      end
      
      define_method(klass, method_name, args, contents)
    end
    
    # Define a singleton method (by defining a method on the object's singleton class)
    eval :defs do |object, method_name, args, contents|
      define_method(eval(object).singleton_class, method_name, args, contents)
    end
    
    eval :const do |const_name|
      constants[const_name]
    end
    
    eval :array do |*contents|
      contents = contents.map { |object| eval(object) }
      constants[:Array].call(:new, contents)
    end
    
    eval :self do
      scope[:self]
    end
    
    # Call a method with a block as an iterator
    eval :iter do |call, args, contents|
      eval(call << Carat::Data::ProcInstance.new(runtime, args, contents))
    end
    
    eval :yield do |*args|
      # Get the current block in this scope
      block = scope.block
      
      # Create a new frame to evaluate the contents of the block
      stack << Frame.new(block.contents, scope.extend)
      
      # Assign the arguments of the block to the values given to yield
      stack.peek.assign(*(block.args + args))
      
      # Now actually execute the frame
      stack.reduce
    end
  end
end
