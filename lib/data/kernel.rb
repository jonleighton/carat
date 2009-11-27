module Carat::Data
  module KernelModule
    extend PrimitiveHost
    
    def primitive_puts(data)
      if data.is_a?(NilClassInstance)
        Kernel.puts(nil)
      else
        Kernel.puts(data)
      end
    end
  end
end
