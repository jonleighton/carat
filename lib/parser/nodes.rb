module Carat
  module Language
    class Program < Treetop::Runtime::SyntaxNode
      def to_ast
        expression_list.to_ast
      end
    end
  
    class ExpressionList < Treetop::Runtime::SyntaxNode
      # An array of nodes representing the expressions in the block
      def expressions
        [first] + rest.elements.map(&:expression)
      end
      
      def to_ast
        Carat::AST::ExpressionList.new(expressions.map(&:to_ast).compact)
      end
    end
    
    class EmptyExpressionList < Treetop::Runtime::SyntaxNode
      def to_ast
        nil
      end
    end
    
    class Expression < Treetop::Runtime::SyntaxNode
      def to_ast
        item.to_ast
      end
    end
    
    class DefinitionNode < Treetop::Runtime::SyntaxNode
      def contents
        definition_body.expression_list.to_ast
      end
    end
    
    class ModuleDefinition < DefinitionNode
      def to_ast
        Carat::AST::ModuleDefinition.new(constant.text_value.to_sym, contents)
      end
    end
    
    class ClassDefinition < DefinitionNode
      def superclass_ast
        if superclass.empty?
          nil
        else
          superclass.primary.to_ast
        end
      end
      
      def to_ast
        Carat::AST::ClassDefinition.new(constant.text_value.to_sym, superclass_ast, contents)
      end
    end
    
    class MethodDefinition < DefinitionNode
      def receiver_ast
        !receiver.empty? && receiver.secondary.to_ast || nil
      end
      
      def to_ast
        Carat::AST::MethodDefinition.new(receiver_ast, method_name.text_value.to_sym, method_argument_pattern.to_ast, contents)
      end
    end
    
    class ArgumentPattern < Treetop::Runtime::SyntaxNode
      def items
        if contents.respond_to?(:head)
          [contents.head] + contents.tail.elements.map(&:item)
        else
          []
        end
      end
      
      def block_pass
        contents.block_pass.local_identifier.text_value unless contents.block_pass.empty?
      end
      
      def to_ast
        if respond_to?(:contents)
          Carat::AST::ArgumentPattern.new(items.map(&:to_ast), block_pass)
        else
          Carat::AST::ArgumentPattern.new
        end
      end
    end
    
    class ArgumentPatternItem < Treetop::Runtime::SyntaxNode
      def default_value
        default.expression.to_ast unless default.empty?
      end
      
      def to_ast
        Carat::AST::ArgumentPatternItem.new(local_identifier.text_value.to_sym, default_value)
      end
    end
    
    class SplatArgumentPatternItem < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::SplatArgumentPatternItem.new(local_identifier.text_value.to_sym)
      end
    end
    
    class Array < Treetop::Runtime::SyntaxNode
      def items
        if respond_to?(:head)
          [head] + tail.elements.map(&:expression)
        else
          []
        end
      end
      
      def to_ast
        Carat::AST::Array.new(items.map(&:to_ast))
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
        Carat::AST::LocalVariable.new(text_value.to_sym)
      end
    end
    
    module LocalVariableOrMethodCall
      def to_ast
        Carat::AST::LocalVariableOrMethodCall.new(text_value.to_sym)
      end
    end
    
    class InstanceVariable < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::InstanceVariable.new(identifier.text_value.to_sym)
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
          method_name = call.method_name.text_value.to_sym
          
          if call.argument_list.empty?
            argument_list = Carat::AST::ArgumentList.new
          else
            argument_list = call.argument_list.to_ast
          end
          
          Carat::AST::MethodCall.new(receiver, method_name, argument_list)
        end
      end
      
      def to_ast
        reduce(chain)
      end
    end
    
    class ImplicitMethodCallChain < MethodCallChain
      def tail_elements
        if tail.empty?
          []
        else
          tail.elements
        end
      end
    
      def chain
        [nil, head] + tail_elements
      end
    end
    
    class BinaryOperation < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::MethodCall.new(
          left.to_ast, name.text_value.to_sym,
          Carat::AST::ArgumentList.new([right.to_ast])
        )
      end
    end
    
    class ArgumentList < Treetop::Runtime::SyntaxNode
      def values
        if !respond_to?(:items) || items.empty?
          []
        else
          [items.head] + items.tail.elements.map(&:argument_list_item)
        end
      end
      
      def block_ast
        block.item.to_ast if respond_to?(:block) && !(block.empty? || block.item.empty?)
      end
      
      def to_ast
        Carat::AST::ArgumentList.new(values.map(&:to_ast), block_ast)
      end
    end
    
    class BlockPass < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::BlockPass.new(expression.to_ast)
      end
    end
    
    class Splat < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Splat.new(expression.to_ast)
      end
    end
    
    class Block < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Block.new(block_argument_pattern.to_ast, expression_list.to_ast)
      end
    end
    
    class Constant < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Constant.new(text_value.to_sym)
      end
    end
    
    class Nothing < Treetop::Runtime::SyntaxNode
      def to_ast
        nil
      end
    end
  end
end
