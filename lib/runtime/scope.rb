class Carat::Runtime
  class Scope
    # We don't allow the constants hash to be publicly accessible, as it is an implementation
    # details, but it still needs to be accessible to other Scopes so that child scopes can copy
    # the pointer to their parent's constants hash.
    attr_accessor :constants
    protected :constants
    
    attr_accessor :block
    
    # Can be initialized with or without a parent, and with a list of assignments. For example:
    # 
    #   Scope.new
    #   Scope.new(parent)
    #   Scope.new(:foo => :bar)
    #   Scope.new(parent, :foo => :bar)
    # 
    # If a parent scope is provided, the parent's table of constants is linked to this scope,
    # because constants are defined globally.
    def initialize(*args)
      @parent = args.first.is_a?(Hash) ? nil : args.shift
      @symbols = args.last || {}
      
      if @parent
        @constants = @parent.constants
      else
        @constants = {}
      end
    end
    
    # Get a local from this table or parent table. May return nil.
    def get(name)
      @locals[name] || @parent && @parent.get(name)
    end
    #alias_method :get, :[]
    
    # Look up a local, raise exception if the name does not exist
    def get!(name)
      get(name) || raise(Carat::CaratError, "local variable '#{name}' is undefined")
    end
    
    # Assign a value to a local. If the local exists in a parent then it gets assigned there,
    # rather than overridden at this level.
    # 
    # The ordering of the logic is quite important. We first check whether the local is defined
    # in this scope only. If so, we change its value. We then check whether any of the parent scopes
    # have a variable matching the given name. If so, we change the value in the parent scope where
    # it has already been defined. If both these cases fail, the local is not defined in any
    # current scope, so we define it for the first time in this scope.
    def []=(name, value)
      if @locals.has_key?(name)
        @locals[name] = value
      elsif parent[name]
        @parent[name] = value
      else
        @locals[name] = value
      end
    end
    
    # Get a constant. May return nil.
    def get_constant(name)
      @constants[name]
    end
    
    # Look up a constant, raise exception if the name does not exist
    def get_constant!(name)
      get_constant(name) || raise(Carat::CaratError, "constant '#{name}' is undefined")
    end
    
    def set_constant(name, value)
      @constants[name] = value
    end
    
    # Assign a hash of multiple local variable name/value pairs
    def merge!(items)
      @locals.merge!(items)
    end
    
    # Create a new scope, using this one as the parent, containing the given assignment
    def extend(assignments = {})
      Scope.new(self, assignments)
    end
  end
end
