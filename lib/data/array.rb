module Carat::Data
  class ArrayClass < ClassInstance
    def new(items)
      object = ArrayInstance.new(runtime, self)
      object.primitive_initialize(*items)
      object
    end
  end
  
  class ArrayInstance < ObjectInstance
    attr_reader :contents
    
    def primitive_initialize(*contents)
      @contents = contents
      self
    end
    
    def primitive_length
      constants[:Fixnum].get(@contents.length)
    end
    
    def primitive_each
      @contents.each do |item|
        call(:yield, [item])
      end
      self
    end
    
    def primitive_push(item)
      @contents << item
      self
    end
    
    def primitive_at(i)
      @contents[i.value] || runtime.nil
    end
  end
end
