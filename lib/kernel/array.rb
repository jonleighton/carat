class Array
  def initialize(*contents)
    Carat.primitive "initialize"
  end
  
  def length
    Carat.primitive "length"
  end
  
  def each
    Carat.primitive "each"
  end
  
  def <<(item)
    Carat.primitive "push"
  end
  
  def [](index)
    Carat.primitive "at"
  end
  
  def to_a
    self
  end
  
  def map
    ary = []
    each { |item| ary << yield(item) }
    ary
  end
  
  def inspect
    "[" + map { |item| item.inspect }.join(", ") + "]"
  end
  
  def join(joiner)
    result = ""
    i = 1
    each do |item|
      result << item
      
      if i != length
        result << joiner
      end
      
      i = i + 1
    end
    result
  end
end
