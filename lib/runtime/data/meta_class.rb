class Carat::Runtime
  class MetaClassInstance < SingletonClassInstance
    def to_s
      "<metaclass:#{parent}>"
    end
  end
end
