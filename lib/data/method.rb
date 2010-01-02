module Carat::Data
  class Method
    attr_reader :argument_pattern, :contents
    
    def initialize(argument_pattern, contents)
      @argument_pattern, @contents = argument_pattern, contents
    end
    
    # Return a hash where the argument names of this method are assigned the given values. This
    # method makes sure the "splat" is dealt with correctly
    # TODO: Deal with blocks
    # TODO: Splat is broken because it creates a Ruby array, not a Carat array object
    def assign_args(argument_list, block)
      argument_map = {}
      
      argument_pattern.items.each do |item|
        case item
          when Carat::AST::ArgumentPatternItem
            argument_map[item.name] = argument_list.shift
          when Carat::AST::SplatArgumentPatternItem
            argument_map[item.name] = argument_list
        end
      end
      
      argument_map
    end
  end
end
