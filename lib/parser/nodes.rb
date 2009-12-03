module Carat
  module Language
    class Block < Treetop::Runtime::SyntaxNode
      # An array of nodes representing the expressions in the block
      def expressions
        [first] + rest.elements.map(&:expression)
      end
      
      def to_ast
        Carat::AST::Block.new(expressions.map(&:to_ast))
      end
    end
    
    class ClassDefinition < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::ClassDefinition.new(constant.text_value, definition_body.to_ast)
      end
    end
    
    class MethodDefinition < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::MethodDefinition.new(identifier.text_value, definition_body.to_ast)
      end
    end
    
    class DefinitionBody < Treetop::Runtime::SyntaxNode
      def to_ast
        block.to_ast
      end
    end
    
    class String < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::String.new(value.text_value)
      end
    end
    
    class True < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::True.new
      end
    end
    
    class False < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::False.new
      end
    end
    
    class Nil < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Nil.new
      end
    end
    
    class Integer < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Integer.new(text_value.to_i)
      end
    end
    
    class Assignment < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Assignment.new(variable.to_ast, expression.to_ast)
      end
    end
    
    module LocalVariable
      def to_ast
        Carat::AST::LocalVariable.new(text_value)
      end
    end
    
    class InstanceVariable < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::InstanceVariable.new(identifier.text_value)
      end
    end
    
    class MethodCall < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::MethodCall.new(receiver.to_ast, identifier.text_value)
      end
    end
    
    class Constant < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Constant.new(text_value)
      end
    end
  end
end
