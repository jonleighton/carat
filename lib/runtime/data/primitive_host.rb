class Carat::Runtime
  module PrimitiveHost
    def self.extended(base)
      if base.instance_of?(Module)
        # If the base is a module which may be further included, we want it to pass along its 
        # primitives when included
        
        base.module_eval do
          def self.included(base2)
            base2.module_primitives.merge!(primitives)
          end
        end
      end
    end
    
    # Allow for primitives to be renamed. This is because we can't (easily) define a method named
    # something like 'primitive_+', so we have to call it 'primitive_plus' - but we still want it
    # to actually represent the '+' method.
    def renamed_primitives
      @renamed_primitives ||= {}
    end
    
    def rename_primitive(from, to)
      renamed_primitives[from] = to
    end
    
    # Primitives defined in modules which are included. Modules should write to this hash when
    # they are included.
    def module_primitives
      @module_primitives ||= {}
    end
    
    def primitives
      # Get all the primitive methods defined on this exact class/module (i.e. exclude ones defined
      # in superclasses or modules)
      primitives = public_instance_methods(false).find_all { |name| name =~ /^primitive_/ }
      
      # Map them to a hash, applying renamings where necessary
      primitives = primitives.inject({}) do |primitives, method_name|
        # Remove the 'primitive_' prefix
        primitive_name = method_name[10..-1].to_sym
        
        # Apply the rename if it exists
        primitive_name = renamed_primitives[primitive_name] || primitive_name
        
        method_name    = method_name.to_sym
        
        primitives[primitive_name] = Primitive.new(method_name)
        primitives
      end
      
      # Combine with the primitives defined by included modules
      module_primitives.merge(primitives)
    end
  end
end
