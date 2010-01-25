module Carat::Data
  class ArrayClass < ClassInstance
    def new(items)
      ArrayInstance.new(runtime, self, items)
    end
  end
  
  class ArrayInstance < ObjectInstance
    attr_reader :contents
    
    def initialize(runtime, klass, contents = [])
      super(runtime, klass)
      @contents = contents
    end
    
    def primitive_initialize(*contents)
      @contents = contents
      yield runtime.nil
    end
    
    def primitive_length
      yield constants[:Fixnum].get(@contents.length)
    end
    
    def primitive_each(&continuation)
      yield_operation = lambda do |item, accumulation, &inner_continuation|
        call(:yield, [item], &inner_continuation)
      end
      
      runtime.fold(nil, yield_operation, @contents) do |result|
        # Throw away result and return the array
        yield self
      end
    end
    
    def primitive_push(item)
      @contents << item
      yield self
    end
    
    def primitive_at(i)
      yield @contents[i.value] || runtime.nil
    end
  end
end
