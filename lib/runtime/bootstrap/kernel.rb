module Carat::Runtime::Bootstrap
  module Kernel
    module SingletonPrimitives
      def puts(data)
        ::Kernel.puts(data)
      end
    end
  end
end
