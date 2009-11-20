module Carat::Runtime::Bootstrap
  module Array
    module Primitives
      def primitive_initialize(*contents)
        @contents = contents
      end
      
      def length
        @contents.length
      end
      
      # TODO: When Array#map works, this can be moved to /lib/kernel
      def inspect
        "[" + @contents.map { |obj| obj.call(:inspect) }.join(", ") + "]"
      end
    end
  end
end
