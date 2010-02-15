module Carat::Data
  class ExceptionClass < ClassInstance
  end
  
  class ExceptionInstance < ObjectInstance
    attr_reader :backtrace
    
    def generate_backtrace(location)
      locations       = [location] + call_stack.reverse.map(&:location)
      enclosing_calls = call_stack.reverse + [nil]
      backtrace       = locations.zip(enclosing_calls)[0..-2]
      
      @backtrace = backtrace.map do |location, enclosing_call|
        "#{location} in #{enclosing_call}"
      end
    end
    
    def primitive_backtrace
      backtrace = @backtrace.map { |line| constants[:String].new(line) }
      yield constants[:Array].new(backtrace)
    end
  end
end
