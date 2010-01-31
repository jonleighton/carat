module Carat::AST
  class Printer
    def initialize
      @indent = 0
    end
    
    def print(root_node)
      print_node(root_node)
    end
    
    private
    
      def print_node(node)
        return indent + "nil" if node.nil?
        
        result = indent + header(node)
        
        unless node.children.empty?
          result << ":\n"
          
          @indent += 1
          result << node.class.attributes.inject([]) do |items, attribute|
            if attribute[:type] == :child
              item = indent + attribute[:name].to_s + ":\n"
              @indent += 1
              item << print_node(node.send(attribute[:name]))
              @indent -= 1
              items << item
            elsif attribute[:type] == :children
              node.send(attribute[:name]).each do |child|
                items << print_node(child)
              end
            end
            
            items
          end.join("\n")
          @indent -= 1
        end
        
        result
      end
      
      def indent
        "  " * @indent
      end
      
      def header(node)
        header = node.class.to_s.sub("Carat::AST::", "")
        unless node.class.properties.empty?
          header << "["
          header << node.class.properties.map do |property|
            node.send(property[:name])
          end.join(", ")
          header << "]"
        end
        header
      end
  end
end
