module MultiJson
  # Handles adapter discovery, loading, and selection.
  #
  # Adapters can be specified as:
  # - Symbol/String: adapter name (e.g., :oj, "json_gem")
  # - Module: adapter class directly
  # - nil/false: use default adapter
  module AdapterSelector
    extend self

    # Alternate spellings for adapter names
    ALIASES = {"jrjackson" => "jr_jackson"}.freeze

    # Strategy lambdas for loading adapters based on specification type.
    # Using lambdas allows the loader dispatch to be a simple hash lookup.
    LOADERS = {
      Module => ->(adapter, _selector) { adapter },
      String => ->(name, selector) { selector.send(:load_adapter_by_name, name) },
      Symbol => ->(name, selector) { selector.send(:load_adapter_by_name, name.to_s) },
      NilClass => ->(_adapter, selector) { selector.send(:load_adapter, selector.default_adapter) },
      FalseClass => ->(_adapter, selector) { selector.send(:load_adapter, selector.default_adapter) }
    }.freeze

    def default_adapter
      @default_adapter ||= detect_best_adapter
    end

    private

    def detect_best_adapter
      loaded_adapter || installable_adapter || fallback_adapter
    end

    def loaded_adapter
      return :fast_jsonparser if defined?(::FastJsonparser)
      return :oj if defined?(::Oj)
      return :yajl if defined?(::Yajl)
      return :jr_jackson if defined?(::JrJackson)
      return :json_gem if defined?(::JSON::Ext::Parser)

      :gson if defined?(::Gson)
    end

    def installable_adapter
      ::MultiJson::REQUIREMENT_MAP.each_key do |adapter_name|
        return adapter_name if try_require(adapter_name)
      end
      nil
    end

    def try_require(adapter_name)
      require ::MultiJson::REQUIREMENT_MAP.fetch(adapter_name)
      true
    rescue ::LoadError
      false
    end

    def fallback_adapter
      warn_about_fallback unless @default_adapter_warning_shown
      @default_adapter_warning_shown = true
      :ok_json
    end

    def warn_about_fallback
      Kernel.warn(
        "[WARNING] MultiJson is using the default adapter (ok_json). " \
        "We recommend loading a different JSON library to improve performance."
      )
    end

    def load_adapter(adapter_spec)
      loader = find_loader_for(adapter_spec)
      return loader.call(adapter_spec, self) if loader

      raise ::LoadError, adapter_spec
    rescue ::LoadError => e
      raise AdapterError.build(e)
    end

    def find_loader_for(adapter_spec)
      klass = adapter_spec.class
      return LOADERS.fetch(klass) if LOADERS.key?(klass)

      LOADERS.fetch(Module) if adapter_spec.is_a?(Module)
    end

    def load_adapter_by_name(name)
      normalized = ALIASES.fetch(name, name).downcase
      require_relative "adapters/#{normalized}"

      class_name = normalized.split("_").map(&:capitalize).join
      ::MultiJson::Adapters.const_get(class_name)
    end
  end
end
