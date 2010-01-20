module Carat
  module Language
    class Node < Treetop::Runtime::SyntaxNode
      # The file is stored by the root node, so we delegate by to the parent by default and then
      # override this in Program
      def file_name
        parent.file_name
      end
      
      def line
        input.line_of(interval.first)
      end
      
      def column
        input.column_of(interval.first) + 1
      end
      
      def error(message)
        raise Carat::SyntaxError.new(input, message, file_name, line, column)
      end
    end
    
    class Program < Node
      attr_accessor :file_name
      
      def to_ast
        expression_list.to_ast
      end
    end
  
    class ExpressionList < Node
      # An array of nodes representing the expressions in the block
      def expressions
        [first] + rest.elements.map(&:expression)
      end
      
      def to_ast
        Carat::AST::ExpressionList.new(expressions.map(&:to_ast).compact)
      end
    end
    
    class EmptyExpressionList < Node
      def to_ast
        nil
      end
    end
    
    class Expression < Node
      def to_ast
        item.to_ast
      end
    end
    
    class DefinitionNode < Node
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
        Carat::AST::MethodDefinition.new(
          receiver_ast, method_name.text_value.to_sym,
          method_argument_pattern.to_ast, contents
        )
      end
    end
    
    class IfExpression < Node
      def false_expression_ast
        false_block.expression_list.to_ast unless false_block.empty?
      end
      
      def true_expression_ast
        true_block.expression_list.to_ast
      end
    
      def to_ast
        Carat::AST::IfExpression.new(
          condition.to_ast,
          true_expression_ast,
          false_expression_ast
        )
      end
    end
    
    class ArgumentPattern < Node
      def items
        @items ||= begin
          if contents.respond_to?(:head)
            items = [contents.head] + contents.tail.elements.map(&:item)
            items.compact.map(&:to_ast)
          else
            []
          end
        end
      end
      
      def splat_count
        items.find_all { |item| item.pattern_type == :splat }.length
      end
      
      def block_pass
        items.find { |item| item.pattern_type == :block_pass }
      end
      
      def validate_items
        # There can only be one splat, otherwise there could be multiple ways to map arguments onto
        # the pattern
        if splat_count > 1
          error "only one splat allowed per method definition"
        end
        
        # A block pass can only occur at the end of the pattern (this also implies there is only
        # one block pass)
        if block_pass && block_pass != items.last
          error "a block pass may only occur at the end of the argument list in a method definition"
        end
      end
      
      def to_ast
        if respond_to?(:contents)
          validate_items
          Carat::AST::ArgumentPattern.new(items)
        else
          Carat::AST::ArgumentPattern.new
        end
      end
    end
    
    class ArgumentPatternItem < Node
      def default_value_ast
        default.expression.to_ast if respond_to?(:default) && !default.empty?
      end
      
      def name
        local_identifier.text_value.to_sym
      end
      
      def type
        case text_value.chars.first
          when '*'
            :splat
          when '&'
            :block_pass
          else
            :normal
        end
      end
      
      def to_ast
        Carat::AST::ArgumentPattern::Item.new(name, type, default_value_ast)
      end
    end
    
    class Array < Node
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
    
    class String < Node
      def to_ast
        Carat::AST::String.new(value.text_value)
      end
    end
    
    class True < Node
      def to_ast
        Carat::AST::True.new
      end
    end
    
    class False < Node
      def to_ast
        Carat::AST::False.new
      end
    end
    
    class Nil < Node
      def to_ast
        Carat::AST::Nil.new
      end
    end
    
    class Integer < Node
      def to_ast
        Carat::AST::Integer.new(text_value.to_i)
      end
    end
    
    class Assignment < Node
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
    
    class InstanceVariable < Node
      def to_ast
        Carat::AST::InstanceVariable.new(identifier.text_value.to_sym)
      end
    end
    
    class MethodCallChain < Node
      def chain
        [receiver] + tail.elements
      end
      
      # This basically resolves the associativity of a method call chain. During parsing, the chain
      # is matched based on right-bracketing, i.e. foo.[bar.[baz]]. However, the call to baz should
      # actually be the outermost node in the AST, and foo.bar is its receiver. So the bracketing
      # in the AST needs to be [[foo].bar].baz
      def reduce(chain)
        if chain.length == 1
          chain.first && chain.first.to_ast
        else
          call = chain.last
          receiver = reduce(chain[0..-2])
          
          if call.argument_list.empty?
            argument_list = Carat::AST::ArgumentList.new
          else
            argument_list = call.argument_list.to_ast
          end
          
          Carat::AST::MethodCall.new(receiver, call.method_name.to_sym, argument_list)
        end
      end
      
      def to_ast
        reduce(chain)
      end
    end
    
    class ArrayAccess < Node
      def method_name
        :[]
      end
      
      def items
        array_brackets.items
      end
      
      def argument_list
        Carat::AST::ArgumentList.new(items)
      end
    end
    
    class ArrayAssign < Node
      def method_name
        :[]=
      end
      
      def items
        array_brackets.items << value.to_ast
      end
      
      def argument_list
        Carat::AST::ArgumentList.new(items)
      end
    end
    
    class ArrayBrackets < Node
      def items
        if respond_to?(:head)
          [head.to_ast] + tail.elements.map(&:argument_list_item).map(&:to_ast)
        else
          []
        end
      end
    end
    
    module MethodName
      def to_sym
        text_value.to_sym
      end
    end
    
    module Identifier
      def to_sym
        text_value.to_sym
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
    
    class BinaryOperation < Node
      def arguments
        [Carat::AST::ArgumentList::Item.new(right.to_ast)]
      end
      
      def to_ast
        Carat::AST::MethodCall.new(
          left.to_ast, name.text_value.to_sym,
          Carat::AST::ArgumentList.new(arguments)
        )
      end
    end
    
    class ArgumentList < Node
      def items
        @items ||= begin
          items = []
          items += [head] + tail.elements.map(&:argument_list_item) if respond_to?(:head)
          items << block_node if respond_to?(:block_node) && !block_node.empty?
          items.map(&:to_ast)
        end
      end
      
      def block_pass
        items.find { |item| item.argument_type == :block_pass }
      end
      
      def block
        items.last if items.last.argument_type == :block
      end
      
      # Note that multiple splats are allowed, when *calling* a method, because there is no
      # ambiguity about how they will be expanded (the n items in the splat's expression will
      # become the next n items in the argument list). This is different to when defining a method
      # because a splat there means a certain variable will take an unbounded number of arguments
      # as a single array.
      def validate_items
        # Either a block may be passed, or a literal block may be created, but not both
        if block_pass && block
          error "cannot pass a block in the arguments and give a literal block at the same time"
        end
        
        # Block pass only valid at end of args. Note this also implies that multiple block passes
        # are invalid.
        if block_pass && block_pass != items.last
          error "a block pass must only occur at the end of the argument list"
        end
      end
      
      def to_ast
        validate_items
        Carat::AST::ArgumentList.new(items)
      end
    end
    
    class ArgumentListItem < Node
      def type
        case text_value.chars.first
          when '*'
            :splat
          when '&'
            :block_pass
          else
            :normal
        end
      end
      
      def to_ast
        Carat::AST::ArgumentList::Item.new(expression.to_ast, type)
      end
    end
    
    class Block < Node
      def to_ast
        Carat::AST::ArgumentList::Item.new(
          Carat::AST::Block.new(
            block_argument_pattern.to_ast,
            expression_list.to_ast
          ),
          :block
        )
      end
    end
    
    class Constant < Node
      def to_ast
        Carat::AST::Constant.new(text_value.to_sym)
      end
    end
    
    class Nothing < Node
      def to_ast
        nil
      end
    end
  end
end
