# frozen_string_literal: true

module MultiJSON
  # Default adapter selection and caching helpers.
  #
  # These methods are split from the main adapter selector to keep the
  # selection logic small while preserving the same module API.
  #
  # @api private
  module AdapterSelector
    # Returns the default parse adapter to use
    #
    # @api private
    # @return [Symbol] adapter name
    # @example
    #   AdapterSelector.default_parse_adapter  #=> :oj
    def default_parse_adapter
      default_adapter_for(:parse)
    end

    # Returns the default generate adapter to use
    #
    # @api private
    # @return [Symbol] adapter name
    # @example
    #   AdapterSelector.default_generate_adapter  #=> :json_gem
    def default_generate_adapter
      default_adapter_for(:generate)
    end

    # Returns the default adapter to use
    #
    # Backwards-compatible alias for the parse-side default.
    #
    # @api private
    # @return [Symbol] adapter name
    # @example
    #   AdapterSelector.default_adapter  #=> :oj
    def default_adapter
      default_parse_adapter
    end

    # Returns the default adapter class, excluding the given adapter name
    #
    # Used by adapters that only implement one direction (e.g.
    # FastJsonparser only parses) so the other direction can be delegated
    # to whichever library MultiJSON would otherwise pick.
    #
    # @api private
    # @param excluded [Symbol] adapter name to skip during detection
    # @param operation [Symbol] :parse or :generate
    # @return [Class] the adapter class
    # @example
    #   AdapterSelector.default_adapter_excluding(:fast_jsonparser)  #=> MultiJSON::Adapters::Oj
    def default_adapter_excluding(excluded, operation: :parse)
      Concurrency.synchronize(:default_adapter) do
        preferences = adapter_preferences(operation)
        name = installable_adapter(preferences, excluding: excluded)
        name ||= loaded_adapter(preferences, excluding: excluded)
        name ||= fallback_adapter
        load_adapter_by_name(name.to_s)
      end
    end

    private

    # Detect or return the cached default adapter for one operation
    #
    # @api private
    # @param operation [Symbol] :parse or :generate
    # @return [Symbol] default adapter name
    def default_adapter_for(operation)
      Concurrency.synchronize(:default_adapter) do
        ivar = :"@default_#{operation}_adapter"
        cached = cached_default_adapter_for(operation, ivar)
        return cached if cached

        detect_and_cache_default_adapter(operation, ivar)
      end
    end

    # Read a cached default adapter if one has already been detected
    #
    # @api private
    # @param operation [Symbol] :parse or :generate
    # @param ivar [Symbol] instance-variable name used for the cache
    # @return [Symbol, nil] cached adapter name when present
    def cached_default_adapter_for(operation, ivar)
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      return unless operation == :parse && instance_variable_defined?(:@default_adapter)

      detected = instance_variable_get(:@default_adapter)
      instance_variable_set(ivar, detected)
      detected
    end

    # Detect and memoize the default adapter for one operation
    #
    # @api private
    # @param operation [Symbol] :parse or :generate
    # @param ivar [Symbol] instance-variable name used for the cache
    # @return [Symbol] detected adapter name
    def detect_and_cache_default_adapter(operation, ivar)
      detected = detect_best_adapter(operation)
      @default_adapter = detected if operation == :parse
      instance_variable_set(ivar, detected)
    end
  end
end
