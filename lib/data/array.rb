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
      yield_operation = lambda do |item, &each_continuation|
        call(:yield, [item], &each_continuation)
      end
      
      runtime.each(yield_operation, @contents, self, &continuation)
    end
    
    def primitive_push(item)
      @contents << item
      yield self
    end
    
    def primitive_get(i)
      yield @contents[i.value] || runtime.nil
    end
    
    def primitive_set(i, value)
      yield @contents[i.value] = value
    end
  end
end
