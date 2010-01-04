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
  
  # TODO: Make this parse
  #def [](index)
  #  Carat.primitive "at"
  #end
  
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
    i = 0
    each do |item|
      i = i + 1
      result << item
      result << joiner if i != length
    end
    result
  end
end
