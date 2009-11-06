require "ruby_parser"
require "forwardable"

module Carat
  ROOT_PATH    = File.expand_path(File.dirname(__FILE__))
  RUNTIME_PATH = ROOT_PATH + "/runtime"
  KERNEL_PATH  = ROOT_PATH + "/kernel"
  
  require RUNTIME_PATH + "/runtime"
  
  # Currently use this for all errors, before implementing exceptions
  class CaratError < StandardError; end
  
  # We convert the sexp from an instance of Sexp to an array. I don't really like the idea of
  # having a Sexp class, sexps are supposed to be a simple data structure and this just adds to
  # the cognitive overhead.
  def self.parse(code)
    RubyParser.new.parse(code).to_a
  end
  
  # Creates a new runtime object and tells it to run some code
  def self.execute(code)
    Runtime.new.run(code)
  end
  
  def self.debug(message)
    puts message
  end
end
