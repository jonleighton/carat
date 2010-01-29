class Array
  def initialize(*contents)
    Primitive.initialize(*contents)
  end
  
  def length
    Primitive.length
  end
  
  def each(&block)
    Primitive.each(&block)
  end
  
  def <<(item)
    Primitive.push
  end
  
  def [](index)
    Primitive.at
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
      result << item.to_s
      
      if i != length
        result << joiner.to_s
      end
      
      i = i + 1
    end
    result
  end
end
