class Carat::Runtime
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
    
    # TODO: When Array#map works, this can be moved to /lib/kernel
    def primitive_inspect
      "[" + @contents.map { |obj| obj.call(:inspect) }.join(", ") + "]"
    end
  end
end
