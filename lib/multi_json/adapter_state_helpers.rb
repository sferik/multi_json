# frozen_string_literal: true

module MultiJSON
  # Shared helper methods for process-wide parse/generate adapter state.
  #
  # Mixed into {MultiJSON} both as singleton and private instance methods so
  # the module_function API and legacy included-instance API can share the same
  # implementation details.
  #
  # @api private
  module AdapterStateHelpers
    private

    # Resolve an adapter specification or directional default
    #
    # @api private
    # @param new_adapter [Symbol, String, Module, nil, false] adapter specification
    # @param operation [Symbol] :parse or :generate
    # @return [Class] loaded adapter class
    def resolve_adapter_or_default(new_adapter, operation)
      return load_adapter(default_adapter_name_for(operation)) if default_adapter_spec?(new_adapter)

      load_adapter(new_adapter)
    end

    # Return the default adapter name for one JSON operation
    #
    # @api private
    # @param operation [Symbol] :parse or :generate
    # @return [Symbol] default adapter name
    def default_adapter_name_for(operation)
      if operation == :parse
        default_parse_adapter
      else
        default_generate_adapter
      end
    end

    # Check whether a specification means "use the default adapter"
    #
    # @api private
    # @param adapter_spec [Object] adapter specification
    # @return [Boolean] true when the spec resets to the default
    def default_adapter_spec?(adapter_spec)
      adapter_spec.nil? || adapter_spec == false
    end

    # Persist both directional adapters and the shared legacy adapter cache
    #
    # @api private
    # @param parse_loaded [Class] loaded parse adapter
    # @param generate_loaded [Class] loaded generate adapter
    # @return [Class] the parse adapter that was stored
    def store_directional_adapters(parse_loaded, generate_loaded)
      Concurrency.synchronize(:adapter) do
        OptionsCache.reset
        @adapter = shared_adapter(parse_loaded, generate_loaded)
        @parse_adapter = parse_loaded
        @generate_adapter = generate_loaded
      end
      parse_loaded
    end

    # Persist a parse adapter change without touching generation
    #
    # @api private
    # @param loaded [Class] loaded parse adapter
    # @return [Class] the parse adapter that was stored
    def store_parse_adapter(loaded)
      Concurrency.synchronize(:adapter) do
        OptionsCache.reset
        @parse_adapter = loaded
        @adapter = shared_adapter(@generate_adapter, loaded)
      end
      loaded
    end

    # Persist a generate adapter change without touching parsing
    #
    # @api private
    # @param loaded [Class] loaded generate adapter
    # @return [Class] the generate adapter that was stored
    def store_generate_adapter(loaded)
      Concurrency.synchronize(:adapter) do
        OptionsCache.reset
        @generate_adapter = loaded
        @adapter = shared_adapter(@parse_adapter, loaded)
      end
      loaded
    end

    # Collapse directional adapters back to the legacy shared adapter cache
    #
    # @api private
    # @param left [Class, nil] first adapter class
    # @param right [Class, nil] second adapter class
    # @return [Class, nil] shared adapter when both sides match
    def shared_adapter(left, right)
      return left if left == right

      nil
    end
  end
end
