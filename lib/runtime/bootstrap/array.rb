module Carat::Runtime::Bootstrap
  module Array
    module Primitives
      def primitive_initialize(*contents)
        @contents = contents
      end
      
      def length
        @contents.length
      end
      
      def inspect
        "[" + @contents.map(&:primitive_inspect).join(", ") + "]"
      end
    end
  end
end
