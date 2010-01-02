# Required at the end of +frame.rb+. Just keeps all the evaluation logic solely in on file, separate
# from the various helper methods defined on +Frame+.

class Carat::Runtime
  class Frame
    # ***** GENERAL ***** #
    
    def eval_expression_list(node)
      node.items.reduce(nil) { |last_result, expression| execute(expression) }
    end
    
    def eval_scope(statement = nil)
      statement && execute(statement) || constants[:NilClass].instance
    end
    
    def eval_const(name)
      constants[name]
    end
    
    def eval_self
      scope[:self]
    end
  
    # ***** LITERALS ***** #
  
    def eval_false
      constants[:FalseClass].instance
    end
    
    def eval_true
      constants[:TrueClass].instance
    end
    
    def eval_nil
      constants[:NilClass].instance
    end
    
    # A literal number value. This is evaluated by the lexer, so we can just use it straight off.
    def eval_lit(value)
      constants[:Fixnum].get(value)
    end
    
    def eval_array(*contents)
      contents = contents.map { |object| execute(object) }
      constants[:Array].call(:new, contents)
    end
    
    def eval_str(contents)
      Carat::Data::StringInstance.new(runtime, contents)
    end
    
    # ***** VARIABLE RETRIEVAL ***** #
    
    # Get a local variable
    def eval_lvar(identifier)
      scope[identifier]
    end
    
    # Get an instance variable
    def eval_ivar(identifier)
      scope[:self].instance_variables[identifier] || constants[:NilClass].instance
    end
    
    # ***** VARIABLE ASSIGNMENT ***** #
    
    def assign(type, left, right)
      case type
        when :lasgn # e.g. [:lasgn, :x, [:lit, :4]]
          scope[left] = execute(right)
        when :iasgn
          scope[:self].instance_variables[left] = execute(right)
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
    
    # Local variable assignment
    def eval_lasgn(left, right)
      assign(:lasgn, left, right)
    end
    
    # Multiple assignment - e.g. x, y = 5, 2
    def eval_masgn(left, right)
      assign(:masgn, left, right)
    end
    
    # Instance variable assignment
    def eval_iasgn(left, right)
      assign(:iasgn, left, right)
    end
    
    # ***** MODULE/CLASS CONSTRUCTS ***** #
    
    def new_module(name)
      Carat::Data::ModuleInstance.new(runtime, name)
    end
    
    def eval_module_definition(node)
      unless constants.has?(node.name)
        constants[node.name] = new_module(node.name)
      end
      scope = SymbolTable.new(:self => constants[node.name])
      execute(node.contents, scope)
    end
    
    def new_class(superclass, name)
      Carat::Data::ClassInstance.new(runtime, execute(superclass) || constants[:Object], name)
    end
    
    def eval_class(class_name, superclass, contents)
      unless constants.has?(class_name)
        constants[class_name] = new_class(superclass, class_name)
      end
      scope = SymbolTable.new(:self => constants[class_name])
      execute(contents, scope)
    end
    
    def eval_sclass(object, contents)
      execute(contents, SymbolTable.new(:self => execute(object).singleton_class))
    end
    
    # ***** CONTROL FLOW CONSTRUCTS ***** #
    
    def eval_if(test, true_expr, false_expr)
      test = execute(test)
      
      if !test.is_a?(Carat::Data::FalseClassInstance) &&
         !test.is_a?(Carat::Data::NilClassInstance)
        execute(true_expr)
      else
        execute(false_expr)
      end
    end
    
    # ***** METHOD DEFINITION ***** #
    
    # Define a method on a given class. +klass+ should be any instance of +Carat::Runtime::Class+.
    def define_method(klass, method_name, args, contents)
      klass.method_table[method_name] = Carat::Data::Method.new(execute(args), contents)
      nil
    end
    
    # Define a method in the current scope
    def eval_method_definition(node)
      if scope[:self].is_a?(Carat::Data::ModuleInstance)
        klass = scope[:self]
      else
        klass = scope[:self].real_klass
      end
      
      define_method(klass, method_name, args, contents)
    end
    
    # Define a singleton method (by defining a method on the object's singleton class)
    def eval_defs(object, method_name, args, contents)
      define_method(execute(object).singleton_class, method_name, args, contents)
    end
    
    # A list of identifiers for the arguments of a method when it is being defined
    def eval_args(*identifiers)
      identifiers
    end
    
    # ***** METHOD CALLING ***** #
    
    # call a method or retrieve a local variable. Unfortunately the sexp does not differentiate
    # between "foo" and "foo()". There is a difference - the second can only be a method call, but
    # the first might be a method call or a local variable lookup.
    def eval_call(receiver, method_name, args, block = nil)
      if receiver.nil? && args == [:arglist] && block.nil?
        # If there is no explicit receiver, and there are no arguments, we are either dealing with
        # a local variable or a method call to 'self'
        
        if scope.has?(method_name)
          scope[method_name]
        else
          scope[:self].call(method_name, args)
        end
      else
        object = receiver && execute(receiver) || scope[:self]
        object.call(method_name, args, block)
      end
    end
    
    # A list of expressions being passed as arguments to a method
    def eval_arglist(*expressions)
      expressions.map { |expression| execute(expression) }.compact
    end
    
    def eval_block_pass(block)
      scope.block = execute(block)
      nil
    end
    
    # ***** BLOCKS ***** #
    
    # Call a method with a block as an iterator
    def eval_iter(call, args, contents)
      block = Carat::Data::ProcInstance.new(runtime, scope, args, contents)
      eval_call(call[1], call[2], call[3], block)
    end
    
    def eval_yield(*argvals)
      # Get the current block in this scope
      block = scope.block
      
      if block.nil?
        raise Carat::CaratError, "no block given"
      end
      
      # Evaluate the argument values in the scope of the "yield" call
      argvals = argvals.map { |arg| execute(arg) }
      
      # Create a new frame to evaluate the contents of the block. Note that we are creating a new
      # scope which extends the block's creation scope - the implication being that all fresh
      # variables inside the block are local to the block. However, variables which were available
      # in the block's creation scope will be available inside the block and can be changed.
      scope       = block.scope.extend
      scope.block = block.scope.block
      frame = stack.push(block.contents, scope)
      
      # Assign the arguments of the block to the values given to yield
      frame.assign(*(block.args + argvals)) unless block.args.nil?
      
      # Now actually evaluate the frame
      stack.reduce
    end
  end
end
