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
    class << self
      def eval(node_type, &block)
        define_method("eval_#{node_type}", &block)
      end
    end
    
    def initialize
      @environment = {}
    end
    
    def set(identifier, value)
      @environment[identifier] = value
    end
    
    def get(identifier)
      @environment[identifier] || raise(RuntimeError, "'#{identifier}' is undefined")
    end
    
    def error(message)
      raise RuntimeError, message
    end
    
    def eval(sexp)
      node_type, body = sexp.first, sexp[1..-1]
      if respond_to?("eval_#{node_type}")
        send("eval_#{node_type}", *body)
      else
        error "'#{node_type}' not implemented"
      end
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
      statements.reduce(nil) { |last_result, statement| eval(statement) }
    end
    
    # Make an assignment
    eval :lasgn do |identifier, value|
      set(identifier, eval(value))
    end
    
    # Get a variable
    eval :lvar do |identifier|
      get(identifier)
    end
    
    # call a method or retrieve a local variable. Unfortunately the sexp does not differentiate
    # between "foo" and "foo()". There is a difference - the second can only be a method call, but
    # the first might be a method call or a local variable lookup.
    eval :call do |receiver, identifier, args|
      if receiver.nil? && eval(args).empty?
        value = get(identifier)
        if false # should be "if value is a method"
          # not implemented - evaluate the method
        else
          value
        end
      else
        # not implemented - get and evaluate the method
      end
    end
    
    eval :arglist do |*identifiers|
      identifiers
    end
  end
end

puts Carat.execute(File.read(ARGV.first))
