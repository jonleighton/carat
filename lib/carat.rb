require "ruby_parser"

module Carat
  ROOT_PATH    = File.expand_path(File.dirname(__FILE__))
  RUNTIME_PATH = ROOT_PATH + "/runtime"
  
  require RUNTIME_PATH + "/runtime"
  
  # Currently use this for all errors, before implementing exceptions
  class CaratError < StandardError; end
  
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
end
