module Carat::Data
  class ArrayClass < ClassInstance
  end
  
  class ArrayInstance < ObjectInstance
    def primitive_initialize(*contents)
      @contents = contents
      self
    end
    
    def primitive_length
      constants[:Fixnum].get(@contents.length)
    end
    
    # FIXME
    def primitive_each
      @contents.each do |item|
        primitive_yield(item)
      end
    end
    
    def primitive_push(item)
      @contents << item
      self
    end
    
    def primitive_at(i)
      @contents[i.value]
    end
  end
end
