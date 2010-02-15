module Carat
  module Language
    module NodeHelper
      # The file is stored by the root node, so we delegate by to the parent by default and then
      # override this in Program
      def file_name
        parent.file_name
      end
      
      def line
        input.line_of(interval.first)
      end
      
      def column
        input.column_of(interval.first)
      end
      
      def location
        Carat::ExecutionLocation.new(file_name, line, column)
      end
      
      def error_location
        Carat::ExecutionLocation.new(file_name, line, column + 1)
      end
      
      def error(message)
        raise Carat::SyntaxError.new(input, message, error_location)
      end
    end
    
    class Treetop::Runtime::SyntaxNode
      include NodeHelper
    end
    
    class Program < Treetop::Runtime::SyntaxNode
      attr_accessor :file_name
      
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
        Carat::AST::ExpressionList.new(location, expressions.map(&:to_ast).compact)
      end
    end
    
    class EmptyExpressionList < Treetop::Runtime::SyntaxNode
      def to_ast
        nil
      end
    end
    
    class BracketedExpression < Treetop::Runtime::SyntaxNode
      def to_ast
        expression.to_ast
      end
    end
    
    class DefinitionNode < Treetop::Runtime::SyntaxNode
      def contents
        definition_body.expression_list.to_ast
      end
    end
    
    class ModuleDefinition < DefinitionNode
      def to_ast
        Carat::AST::ModuleDefinition.new(location, constant.text_value.to_sym, contents)
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
        Carat::AST::ClassDefinition.new(
          location, constant.text_value.to_sym,
          superclass_ast, contents
        )
      end
    end
    
    class MethodDefinition < DefinitionNode
      def receiver_ast
        !receiver.empty? && receiver.primary.to_ast || nil
      end
      
      def to_ast
        Carat::AST::MethodDefinition.new(
          location,
          receiver_ast, method_name.text_value.to_sym,
          method_argument_pattern.to_ast, contents
        )
      end
    end
    
    class IfExpression < Treetop::Runtime::SyntaxNode
      def false_expression_ast
        false_block.to_ast unless false_block.empty?
      end
      
      def true_expression_ast
        true_block.expression_list.to_ast
      end
    
      def to_ast
        Carat::AST::If.new(
          location, condition.to_ast,
          true_block.to_ast, false_expression_ast
        )
      end
    end
    
    class ElseExpression < Treetop::Runtime::SyntaxNode
      def to_ast
        expression_list.to_ast
      end
    end
    
    class WhileExpression < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::While.new(location, condition.to_ast, contents.to_ast)
      end
    end
    
    class BeginExpression < Treetop::Runtime::SyntaxNode
      def rescue_ast
        self.rescue.to_ast unless self.rescue.empty?
      end
    
      def to_ast
        Carat::AST::Begin.new(location, contents.to_ast, rescue_ast)
      end
    end
    
    class RescueExpression < Treetop::Runtime::SyntaxNode
      def type_ast
        type.expression.to_ast unless type.empty?
      end
      
      def assignment_ast
        assignment.variable.to_ast unless assignment.empty?
      end
      
      def to_ast
        Carat::AST::Rescue.new(location, type_ast, assignment_ast, contents.to_ast)
      end
    end
    
    class ArgumentPattern < Treetop::Runtime::SyntaxNode
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
        items.find_all { |item| item.type == :splat }.length
      end
      
      def multiple_splats?
        splat_count > 1
      end
      
      def block_pass
        @block_pass ||= items.find { |item| item.type == :block_pass }
      end
      
      def block_pass_last?
        block_pass == items.last
      end
      
      def optional_part
        items.drop_while { |item| item.mandatory? }
      end
      
      def mandatory_before_optional?
        optional_part.find { |item| item.mandatory? }.nil?
      end
      
      def unique_item_names
        items.map { |item| item.name }.uniq
      end
      
      def duplicate_names?
        items.length > unique_item_names.length
      end
      
      def validate_items
        # There can only be one splat, otherwise there could be multiple ways to map arguments onto
        # the pattern
        if multiple_splats?
          error "only one splat allowed per method definition"
        end
        
        # This also implies there is only one block pass
        if block_pass && !block_pass_last?
          error "a block pass may only occur at the end of the argument list in a method definition"
        end
        
        unless mandatory_before_optional?
          error "all mandatory arguments must come before any optional ones"
        end
        
        if duplicate_names?
          error "duplicate argument name(s)"
        end
      end
      
      def to_ast
        if respond_to?(:contents)
          validate_items
          Carat::AST::ArgumentPattern.new(location, items)
        else
          Carat::AST::ArgumentPattern.new(location)
        end
      end
    end
    
    class ArgumentPatternItem < Treetop::Runtime::SyntaxNode
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
        Carat::AST::ArgumentPattern::Item.new(location, name, type, default_value_ast)
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
        Carat::AST::Array.new(location, items.map(&:to_ast))
      end
    end
    
    class String < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::String.new(location, contents)
      end
    end
    
    class StringWithoutInterpolation < String
      def contents
        value.text_value
      end
    end
    
    class StringWithInterpolation < String
      def contents
        value.text_value.
          gsub('\n', "\n").
          gsub('\r', "\r").
          gsub('\t', "\t")
      end
    end
    
    class True < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::True.new(location)
      end
    end
    
    class False < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::False.new(location)
      end
    end
    
    class Nil < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Nil.new(location)
      end
    end
    
    class Integer < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Integer.new(location, text_value.to_i)
      end
    end
    
    module LocalVariable
      def to_ast
        Carat::AST::LocalVariable.new(location, text_value.to_sym)
      end
    end
    
    module LocalVariableOrMethodCall
      def to_ast
        Carat::AST::LocalVariableOrMethodCall.new(location, text_value.to_sym)
      end
    end
    
    class InstanceVariable < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::InstanceVariable.new(location, identifier.text_value.to_sym)
      end
    end
    
    class MethodCallChain < Treetop::Runtime::SyntaxNode
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
            argument_list = Carat::AST::ArgumentList.new(location)
          else
            argument_list = call.argument_list.to_ast
          end
          
          Carat::AST::MethodCall.new(location, receiver, call.method_name.to_sym, argument_list)
        end
      end
      
      def to_ast
        reduce(chain)
      end
    end
    
    class ArrayAccess < Treetop::Runtime::SyntaxNode
      def method_name
        :[]
      end
      
      def items
        array_brackets.items
      end
      
      def argument_list
        Carat::AST::ArgumentList.new(location, items)
      end
    end
    
    class ArrayAssign < Treetop::Runtime::SyntaxNode
      def method_name
        :[]=
      end
      
      def items
        array_brackets.items << value.to_ast
      end
      
      def argument_list
        Carat::AST::ArgumentList.new(location, items)
      end
    end
    
    class ArrayBrackets < Treetop::Runtime::SyntaxNode
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
    
    class UnaryMethodCall < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::MethodCall.new(
          location, receiver.to_ast, (name.text_value * 2).to_sym,
          Carat::AST::ArgumentList.new(location)
        )
      end
    end
    
    class Assignment < Treetop::Runtime::SyntaxNode
      def receiver_ast
        @receiver_ast ||= receiver.to_ast
      end
      
      def value_ast
        value.to_ast
      end
      
      def to_ast
        Carat::AST::Assignment.new(location, receiver_ast, value_ast)
      end
    end
    
    module BinaryMethodHelper
      def method_call(left, name, right)
        Carat::AST::MethodCall.new(
          location, left.to_ast, name.text_value.to_sym,
          Carat::AST::ArgumentList.new(
            location, [
              Carat::AST::ArgumentList::Item.new(location, right.to_ast)
            ]
          )
        )
      end
    end
    
    class BinaryMethodCall < Treetop::Runtime::SyntaxNode
      include BinaryMethodHelper
      
      def to_ast
        method_call(left, name, right)
      end
    end
    
    class BinaryMethodAssignment < Assignment
      include BinaryMethodHelper
      
      def value_ast
        method_call(receiver, name, value)
      end
    end
    
    class BinaryOperation < Treetop::Runtime::SyntaxNode
      OPERATIONS = {
        "&&" => Carat::AST::And,
        "||" => Carat::AST::Or
      }
      
      def to_ast
        OPERATIONS[name.text_value].new(location, left.to_ast, right.to_ast)
      end
    end
    
    class BinaryOperationAssignment < Assignment
      def value_ast
        BinaryOperation::OPERATIONS[name.text_value].new(location, receiver_ast, value.to_ast)
      end
    end
    
    class ArgumentList < Treetop::Runtime::SyntaxNode
      def items
        @items ||= begin
          items = []
          items += [head] + tail.elements.map(&:argument_list_item) if respond_to?(:head)
          items << block_node if respond_to?(:block_node) && !block_node.empty?
          items.map(&:to_ast)
        end
      end
      
      def block_pass
        items.find { |item| item.type == :block_pass }
      end
      
      def block
        items.last if items.last.type == :block
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
        Carat::AST::ArgumentList.new(location, items)
      end
    end
    
    class ArgumentListItem < Treetop::Runtime::SyntaxNode
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
        Carat::AST::ArgumentList::Item.new(location, expression.to_ast, type)
      end
    end
    
    class Block < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::ArgumentList::Item.new(
          location,
          Carat::AST::Block.new(
            location, block_argument_pattern.to_ast,
            expression_list.to_ast
          ),
          :block
        )
      end
    end
    
    class Constant < Treetop::Runtime::SyntaxNode
      def to_ast
        Carat::AST::Constant.new(location, text_value.to_sym)
      end
    end
    
    class Nothing < Treetop::Runtime::SyntaxNode
      def to_ast
        nil
      end
    end
  end
end
