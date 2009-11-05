require "rubygems"
require "ruby_parser"

module Carat
  # This looks weird, but it's creating a Carat::RuntimeError class
  class RuntimeError < ::RuntimeError; end
  
  # We convert the sexp from an instance of Sexp to an array. I don't really like the idea of
  # having a Sexp class, sexps are supposed to be a simple data structure and this just adds to
  # the cognitive overhead.
  def self.execute(code)
    sexp = RubyParser.new.parse(code).to_a
    debug "Sexp: #{sexp.inspect}"
    Runtime.new.eval(sexp)
  end
    
  def self.debug(message)
    puts message
  end
  
  class Runtime
    class Object
      attr_reader :klass, :instance_variables
      
      def initialize(klass)
        @klass = klass
        @instance_variables = {}
      end
      
      def lookup_method(method_name)
        klass.methods[method_name]
      end
      
      def to_s
        "<object:#{klass}>"
      end
    end
  
    class Class < Object
      attr_reader :methods, :name, :superclass
      
      def initialize(name, superclass)
        super(nil) # TODO: Should be reference to Class object in the object language
        @name, @superclass = name, superclass
        @methods = {}
      end
      
      def to_s
        "<class:#{name}>"
      end
    end
    
    class Method
      attr_reader :args, :contents
      
      def initialize(args, contents)
        @args, @contents = args, contents
      end
    end
    
    # The top level scope takes care of "globals". In this context "globals" can either be constants
    # (which are globally available) or actual global variables.
    class TopLevelScope
      attr_reader :symbols, :globals
      
      def initialize(self_object)
        @symbols = { :self => self_object }
        @globals = {}
      end
      
      def []=(symbol, value)
        symbols[symbol] = value
      end
      
      def [](symbol)
        symbols[symbol] || raise(RuntimeError, "local variable '#{symbol}' is undefined")
      end
      
      # TODO: Make this work
      # For now:
      alias_method :constants, :globals
      alias_method :global_variables, :globals
=begin
      def constants[]=(symbol, value)
        globals[symbol] = value
      end
      
      def constants[](symbol)
        globals[symbol] || raise(RuntimeError, "constant '#{symbol}' is undefined")
      end
      
      def global_variables[]=(symbol, value)
        globals[symbol] = value
      end
      
      def global_variables[](symbol)
        globals[symbol] || raise(RuntimeError, "global variable '#{symbol}' is undefined")
      end
=end
    end
    
    # Standard Scopes have a parent, and they use the hierarchy to lookup globals
    class Scope < TopLevelScope
      attr_reader :parent
      
      def initialize(self_object, parent)
        super(self_object)
        @parent = parent
      end
      
      def globals
        parent.globals
      end
      
      def [](symbol)
        symbols[symbol] || parent[symbol]
      end
    end
    
    class Stack < Array
      # Accept a frame onto the stack, evaluate it, then remove it
      def <<(frame)
        super(frame)
        result = frame.eval(self)
        pop
        result
      end
    end
    
    # Evaluates a sexp within the given scope. This is where all the evaluation logic lives.
    class Frame
      attr_reader :sexp, :scope
      
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
        raise RuntimeError, message
      end
      
      # Theoretically a frame can exist independently of a stack, but when we are evaluating the
      # frame we need a reference to the stack so that we can add new frames to it.
      def eval(stack)
        @stack = stack
        if respond_to?("eval_#{sexp_type}")
          send("eval_#{sexp_type}", *sexp_body) unless sexp_body.empty?
        else
          error "'#{sexp_type}' not implemented"
        end
      ensure
        @stack = nil
      end
      
      # Creates a new frame for the sexp and scope, and adds it to the current stack. If scope is
      # not given, it will default to the current scope.
      def stack_eval(sexp, scope = nil)
        @stack << Frame.new(sexp, scope || self.scope)
      end
      
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
            raise RuntimeError, "not implemented"
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
    
    def initialize
      @scope = TopLevelScope.new(nil)
    end
    
    def eval(sexp)
      @stack = Stack.new
      @frame = Frame.new(sexp, @scope)
      @stack << @frame
    end
  end
end

puts Carat.execute(File.read(ARGV.first))
