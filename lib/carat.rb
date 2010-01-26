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
  AST_PATH     = ROOT_PATH + "/ast"
  PARSER_PATH  = ROOT_PATH + "/parser"
  
  # TODO: Replace all occurances with something more specific
  class CaratError < StandardError; end
  
  require RUNTIME_PATH + "/runtime"
  require DATA_PATH    + "/data"
  require AST_PATH     + "/ast"
  require PARSER_PATH  + "/parser"
  
  def self.parse(input, file_name = nil)
    LanguageParser.new(input, file_name).run!
  end
  
  def self.run(input)
    Runtime.new.run(input)
  end
  
  def self.run_file(name)
    Runtime.new.run_file(name)
  end
end
