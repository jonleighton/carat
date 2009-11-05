class Carat::Runtime
  class Array < Class
    def to_s
      @methods[:inspect].definition.call
    end
    
    primitive :initialize do |*contents|
      @contents = contents
    end
    
    primitive :length do
      @contents.length
    end
    
    primitive :inspect do
      @contents.inspect
    end
  end
end
