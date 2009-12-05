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
    
    class EmptyBlock < Treetop::Runtime::SyntaxNode
      def to_ast
        nil
      end
    end
    
    class DefinitionNode < Treetop::Runtime::SyntaxNode
      def contents
        definition_body.block.to_ast
      end
    end
    
    class ClassDefinition < DefinitionNode
      def to_ast
        Carat::AST::ClassDefinition.new(constant.text_value, contents)
      end
    end
    
    class MethodDefinition < DefinitionNode
      def to_ast
        Carat::AST::MethodDefinition.new(identifier.text_value, contents)
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
    
    module LocalVariableOrMethodCall
      def to_ast
        Carat::AST::LocalVariableOrMethodCall.new(text_value)
      end
    end
    
    class InstanceVariable < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::InstanceVariable.new(identifier.text_value)
      end
    end
    
    class MethodCallChain < Treetop::Runtime::SyntaxNode
      def chain
        [receiver] + tail.elements
      end
      
      def reduce(chain)
        if chain.length == 1
          chain.first && chain.first.to_ast
        else
          call = chain.last
          
          receiver = reduce(chain[0..-2])
          method_name = call.identifier.text_value
          
          if call.arguments.empty?
            arguments = Carat::AST::ArgumentList.new
          else
            arguments = call.arguments.to_ast
          end
          
          Carat::AST::MethodCall.new(receiver, method_name, arguments)
        end
      end
      
      def to_ast
        reduce(chain)
      end
    end
    
    class ImplicitMethodCallChain < MethodCallChain
      def chain
        [nil, head] + tail.elements
      end
    end
    
    class ArgumentList < Treetop::Runtime::SyntaxNode
      def values
        [first] + rest.elements.map(&:expression)
      end
      
      def to_ast
        Carat::AST::ArgumentList.new(values.map(&:to_ast))
      end
    end
    
    class EmptyArgumentList < ArgumentList
      def values
        []
      end
    end
    
    class Constant < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Constant.new(text_value)
      end
    end
    
    class Nothing < Treetop::Runtime::SyntaxNode
      def to_ast
        nil
      end
    end
  end
end
