module Carat::Data
  module KernelModule
    extend PrimitiveHost
    
    def primitive_puts(data)
      Kernel.puts(data)
    end
  end
end