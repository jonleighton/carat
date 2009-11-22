class Carat::Runtime
  class KernelModule < ModuleInstance
    module Primitives
      extend PrimitiveHost
      
      def primitive_puts(data)
        Kernel.puts(data)
      end
    end
    
    include Primitives
  end
end
