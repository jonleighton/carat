# The top level scope takes care of "globals". In this context "globals" can either be constants
# (which are globally available) or actual global variables.
class Carat::Runtime
  class TopLevelScope < AbstractScope
    attr_reader :runtime, :globals
    
    def initialize(runtime, self_object)
      super(self_object)
      @runtime, @globals = runtime, {}
    end
    
    def initialize_environment
      object_klass = constants[:Object] = ObjectClass.new(runtime, :Object, nil)
      class_klass  = constants[:Class]  = ClassClass.new(runtime, :Class,  object_klass)
      
      object_klass.klass = class_klass
      
      constants[:Fixnum] = Fixnum.new(runtime, :Fixnum, object_klass)
      constants[:Array]  = Array.new(runtime, :Array, object_klass)
    end
    
    def [](symbol)
      super || raise(Carat::CaratError, "local variable '#{symbol}' is undefined")
    end
    
    alias_method :constants, :globals
    alias_method :global_variables, :globals
  end
end
