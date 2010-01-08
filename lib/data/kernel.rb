module Carat::Data
  module KernelModule
    def primitive_puts(object)
      if object.is_a?(NilClassInstance)
        Kernel.puts("nil")
      else
        # object.call(:to_s) gets the StringInstance representing the object, and then calling
        # to_s actually gets the string.
        Kernel.puts(object.call(:to_s).to_s)
      end
      
      constants[:NilClass].instance
    end
  end
end
