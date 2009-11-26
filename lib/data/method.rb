module Carat::Data
  class Method
    attr_reader :args, :contents
    
    def initialize(args, contents)
      @args, @contents = args, contents
    end
    
    # Return a hash where the argument names of this method are assigned the given values. This
    # method makes sure the "splat" is dealt with correctly
    def assign_args(values, block)
      args.inject({}) do |args_map, name|
        case name.to_s
          when /\*(.+)/
            args_map[$1.to_sym] = values
          when /\&(.+)/
            args_map[$1.to_sym] = block
          else
            args_map[name] = values.shift
        end
        
        args_map
      end
    end
  end
end
