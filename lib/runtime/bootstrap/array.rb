module Carat::Runtime::Bootstrap
  module Array
    module Primitives
      def initialize(*contents)
        @contents = contents
      end
      
      def length
        @contents.length
      end
      
      def inspect
        @contents.inspect
      end
    end
  end
end
