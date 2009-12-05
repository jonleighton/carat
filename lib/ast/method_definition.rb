module Carat::AST
  class MethodDefinition < Node
    attr_reader :receiver, :name, :contents
    
    def initialize(receiver, name, contents)
      @receiver, @name, @contents = receiver, name, contents
    end
    
    def inspect
      super + "[#{name}]:\n" +
        "Receiver:\n" + indent(receiver.inspect) + "\n" +
        "Contents:\n" + indent(contents.inspect)
    end
  end
end
