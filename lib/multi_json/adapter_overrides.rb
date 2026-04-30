# frozen_string_literal: true

module MultiJSON
  # Fiber-local adapter overrides used by {MultiJSON.with_adapter}.
  #
  # Kept in a separate module so the main {MultiJSON} module stays focused
  # on the parse/generate public API surface.
  #
  # @api private
  module AdapterOverrides
    # Temporarily override one or both adapters for the duration of a block
    #
    # @api public
    # @param new_adapter [Symbol, String, Module, Hash, nil, false] adapter specification
    # @yield block to execute with the temporary adapter override
    # @return [Object] block result
    # @example Override only generation inside a block
    #   MultiJSON.with_adapter(generate: :json_gem) do
    #     MultiJSON.generate(foo: "bar")
    #   end
    def with_adapter(new_adapter)
      # @type var previous_override: Module?
      previous_override = Fiber[:multi_json_adapter]
      # @type var previous_parse_override: Module?
      previous_parse_override = Fiber[:multi_json_parse_adapter]
      # @type var previous_generate_override: Module?
      previous_generate_override = Fiber[:multi_json_generate_adapter]

      apply_adapter_override(new_adapter, previous_parse_override, previous_generate_override)
      yield
    ensure
      Fiber[:multi_json_adapter] = previous_override
      Fiber[:multi_json_parse_adapter] = previous_parse_override
      Fiber[:multi_json_generate_adapter] = previous_generate_override
    end

    private

    # Apply a block-scoped adapter override
    #
    # @api private
    # @param new_adapter [Symbol, String, Module, Hash, nil, false] adapter specification
    # @param previous_parse_override [Class, nil] previous parse override
    # @param previous_generate_override [Class, nil] previous generate override
    # @return [void]
    def apply_adapter_override(new_adapter, previous_parse_override, previous_generate_override)
      if new_adapter.is_a?(Hash)
        apply_directional_override(new_adapter, previous_parse_override, previous_generate_override)
      elsif default_adapter_spec?(new_adapter)
        apply_default_override
      else
        Fiber[:multi_json_adapter] = load_adapter(new_adapter)
      end
    end

    # Apply parse/generate overrides independently for the current fiber
    #
    # @api private
    # @param new_adapter [Hash] directional adapter specification
    # @param previous_parse_override [Class, nil] previous parse override
    # @param previous_generate_override [Class, nil] previous generate override
    # @return [void]
    def apply_directional_override(new_adapter, previous_parse_override, previous_generate_override)
      Fiber[:multi_json_parse_adapter] =
        override_adapter_for(new_adapter, :parse, default_parse_adapter, previous_parse_override)
      Fiber[:multi_json_generate_adapter] =
        override_adapter_for(new_adapter, :generate, default_generate_adapter, previous_generate_override)
    end

    # Restore the auto-detected defaults inside the current fiber
    #
    # @api private
    # @return [void]
    def apply_default_override
      Fiber[:multi_json_parse_adapter] = load_adapter(default_parse_adapter)
      Fiber[:multi_json_generate_adapter] = load_adapter(default_generate_adapter)
    end

    # Resolve one directional override entry from a hash spec
    #
    # @api private
    # @param new_adapter [Hash] directional adapter specification
    # @param key [Symbol] operation key to read
    # @param default_adapter [Symbol] default adapter name for the operation
    # @param previous_override [Class, nil] previous override to preserve
    # @return [Class, nil] loaded adapter or preserved previous override
    def override_adapter_for(new_adapter, key, default_adapter, previous_override)
      return previous_override unless new_adapter.key?(key)

      value = new_adapter[key]
      return load_adapter(default_adapter) if default_adapter_spec?(value)

      load_adapter(value)
    end
  end
end
