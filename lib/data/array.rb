module Carat::Data
  class ArrayClass < ClassInstance
  end
  
  class ArrayInstance < ObjectInstance
    def primitive_initialize(*contents)
      @contents = contents
      self
    end
    
    def primitive_length
      @contents.length
    end
    
    def primitive_each(*args)
      @contents.each do |item|
        current_frame.eval_yield(item)
      end
    end
    
    def primitive_push(item)
      @contents << item
      self
    end
    rename_primitive :push, :<<
    
    def primitive_at(i)
      @contents[i.value]
    end
    rename_primitive :at, :[]
  end
end
