module Carat::AST
  class MethodCall < Node
    attr_reader :receiver, :name
    
    def initialize(receiver, name)
      @receiver, @name = receiver, name
    end
    
    def inspect
      super + "[#{name}]:\n" + indent(receiver.inspect)
    end
  end
end
