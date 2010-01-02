begin
  require "rubygems"
rescue LoadError
  # We don't require rubygems to be present, but load it if it is
end

require "forwardable"
require "treetop"

module Carat
  ROOT_PATH    = File.expand_path(File.dirname(__FILE__))
  RUNTIME_PATH = ROOT_PATH + "/runtime"
  DATA_PATH    = ROOT_PATH + "/data"
  KERNEL_PATH  = ROOT_PATH + "/kernel"
  PARSER_PATH  = ROOT_PATH + "/parser"
  AST_PATH     = ROOT_PATH + "/ast"
  
  require RUNTIME_PATH + "/runtime"
  require DATA_PATH    + "/data"
  require PARSER_PATH  + "/parser"
  require AST_PATH     + "/ast"
  
  # Currently use this for all errors, before implementing exceptions
  class CaratError < StandardError; end
  
  def self.parse(code)
    parser = Carat::LanguageParser.new
    parse_tree = parser.parse(code)
    
    if parse_tree
      parse_tree.to_ast
    else
      puts "Syntax error:"
      puts parser.failure_reason
      exit 1
    end
  end
  
  # Creates a new runtime object and tells it to run some code
  def self.execute(code, debug = false)
    @debug = debug
    Runtime.new.run(code).to_s
  ensure
    @debug = false
  end
  
  def self.debug(message)
    puts message if @debug
  end
end
