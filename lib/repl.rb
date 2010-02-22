require 'readline'

module Carat
  class REPL
    def initialize
      @runtime    = Carat::Runtime.new
      @scope      = @runtime.main_scope
      @expression = ""
    end
    
    def run
      puts "Welcome to Carat."
      loop { readline }
    end
    
    def readline
      line = Readline.readline(prompt)
      exit(0) if line == "exit"
      
      @expression << line + "\n"
      
      begin
        ast = Carat.parse(@expression)
        result = @runtime.execute(ast, @scope)
        inspected_result = @runtime.with_stack do
          result.call(:inspect, &@runtime.identity_continuation)
        end
        
        puts "=> " + inspected_result.to_s
        @expression = ""
      rescue SyntaxError
        # It's assumed that syntax errors mean the expression is incomplete, so we just rescue
        # them and carry on
      end
    rescue Interrupt
      if @expression.empty?
        # Exit silently
        puts
        exit(0)
      else
        # Reset the current expression, but don't exit the REPL
        @expression = ""
        puts
      end
    end
    
    def prompt
      if @expression.empty?
        ">> "
      else
        "?> "
      end
    end
  end
end
