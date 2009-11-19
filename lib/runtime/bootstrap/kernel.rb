module Carat::Runtime::Bootstrap
  module Kernel
    module Primitives
      def puts(data)
        ::Kernel.puts(data)
      end
    end
  end
end
