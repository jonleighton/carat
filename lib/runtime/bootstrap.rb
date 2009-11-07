module Carat::Runtime::Bootstrap
  Dir[Carat::RUNTIME_PATH + "/bootstrap/*.rb"].each do |file|
    require file
  end
  
  def self.rename_primitives(mod)
    mod.instance_methods.each do |method_name|
      unless method_name =~ /^primitive_/
        mod.module_eval do
          alias_method "primitive_#{method_name}", method_name
          remove_method method_name
        end
      end
    end
  end
  
  # Rename every method to give it a "primitive_" prefix. This is to prevent name conflicts when the
  # module is included in the object.
  constants.each do |constant|
    mod = const_get(constant)
    rename_primitives(mod.const_get(:ClassPrimitives))  if mod.const_defined?(:ClassPrimitives)
    rename_primitives(mod.const_get(:ObjectPrimitives)) if mod.const_defined?(:ObjectPrimitives)
  end
end
