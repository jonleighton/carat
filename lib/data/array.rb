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
      @contents[i.value] || constants[:NilClass].instance
    end
  end
end
