class Carat::Runtime
  class MetaClass < SingletonClass
    def to_s
      "<metaclass:#{parent}>"
    end
  end
end
