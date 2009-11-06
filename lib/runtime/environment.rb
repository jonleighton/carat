class Carat::Runtime
  class Environment
    attr_reader :runtime
  
    extend Forwardable
    def_delegators :runtime, :constants
    
    def initialize(runtime)
      @runtime = runtime
    end
    
    def setup
      object_klass = constants[:Object] = Class.new(runtime, :Object, nil)
      class_klass  = constants[:Class]  = Class.new(runtime, :Class,  object_klass)
      
      object_klass.klass = class_klass
      
      constants[:Fixnum] = Class.new(runtime, :Fixnum, object_klass)
      constants[:Array]  = Class.new(runtime, :Array,  object_klass)
    end
  end
end
