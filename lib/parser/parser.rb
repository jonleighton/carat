module Carat
  require "rubygems" rescue LoadError
  require "treetop"
  
  if ENV["DYNAMIC_PARSER"] == "true"
    Treetop.load(PARSER_PATH + "/language")
  else
    require PARSER_PATH + "/language"
  end
  
  require PARSER_PATH + "/nodes"

  class SyntaxError < CaratError
    attr_reader :input, :message, :location
    
    extend Forwardable
    def_delegators :location, :file_name, :line, :column
    
    def initialize(input, message, location)
      @input, @message, @location = input, message, location
    end
    
    # The input text on the offending line
    def line_contents
      input.split("\n")[line - 1]
    end
    
    # The line contents with an arrow underneath pointing at the column
    def diagram
      line_contents + "\n" + (" " * (column - 1)) + "^"
    end
    
    def full_message
      "#{location}: #{message}\n\n#{diagram}"
    end
  end
  
  class ParseError < SyntaxError; end
  
  # Adapts the parser to store the code and the file name. This means we can break up the process of
  # parsing a bit more easily.
  class LanguageParser < Treetop::Runtime::CompiledParser
    attr_reader :input, :file_name
    
    def initialize(input, file_name)
      super()
      @input, @file_name = input, file_name
    end
    
    # Parses the code converts it to an AST, raising syntax errors along the way if necessary
    def ast
      @ast ||= begin
        parse_tree.file_name = file_name
        parse_tree.to_ast
      end
    end
    
    def parse_tree
      @parse_tree ||= begin
        tree = parse(input_without_comments)
        if tree.nil?
          raise Carat::ParseError.new(
            input, expected_message,
            Carat::ExecutionLocation.new(file_name, failure_line, failure_column)
          )
        end
        tree
      end
    end
    
    def input_without_comments
      input.gsub(/##.*?##/m, '').gsub(/#[^\n]*/, '')
    end
    
    def expected_message
      tf = terminal_failures
      message = "Expected "
      message << "one of " if tf.length > 1
      message << tf.map(&:expected_string).uniq.join(', ')
    end
  end
end
