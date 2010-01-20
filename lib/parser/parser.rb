# TODO: Replace with pre-generated parser when it has stabilised a bit
Treetop.load(Carat::PARSER_PATH + "/language")
require Carat::PARSER_PATH + "/nodes"

module Carat
  class SyntaxError < CaratError
    attr_reader :input, :message, :file_name, :line, :column
    
    def initialize(input, message, file_name = nil, line = nil, column = nil)
      @input, @message = input, message
      @file_name, @line, @column = file_name, line, column
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
      "#{file_name} at ln #{line}, col #{column}: #{message}\n\n#{diagram}"
    end
  end
  
  # Adapts the parser to store the code and the file name. This means we can break up the process of
  # parsing a bit more easily.
  class LanguageParser < Treetop::Runtime::CompiledParser
    attr_reader :input, :file_name
    
    def initialize(input, file_name)
      super()
      @input, @file_name = input, file_name
    end
    
    # Parses the code converts it to an AST, raising syntax errors along the way if necessary
    def run!
      parse_tree.file_name = file_name
      parse_tree.to_ast
    rescue StandardError => e
      # SyntaxErrors are okay, but anything else shouldn't really happen, so we want to output the
      # parse tree for debugging in that case
      unless e.is_a?(SyntaxError)
        p parse_tree
        puts
      end
      raise e
    end
    
    def parse_tree
      @parse_tree ||= begin
        tree = parse(input)
        if tree.nil?
          raise Carat::SyntaxError.new(input, expected_message, file_name, failure_line, failure_column)
        end
        tree
      end
    end
    
    def expected_message
      tf = terminal_failures
      message = "Expected "
      message << "one of " if tf.length > 1
      message << tf.map(&:expected_string).uniq.join(', ')
    end
  end
end
