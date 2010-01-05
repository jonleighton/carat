class Class < Module
  def allocate
    Carat.primitive "allocate"
  end
  
  def new
    Carat.primitive "new"
  end
end
