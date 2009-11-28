class Array
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
