module Carat::Data
  module KernelModule
    extend PrimitiveHost
    
    def primitive_puts(data)
      if data.is_a?(NilClassInstance)
        Kernel.puts("nil")
      else
        # data.call(:to_s) gets the StringInstance representing the string, and then calling
        # to_s actually gets the string.
        Kernel.puts(data.call(:to_s).to_s)
      end
    end
  end
end
