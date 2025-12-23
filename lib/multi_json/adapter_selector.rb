module MultiJson
  module AdapterSelector
    extend self

    ALIASES = {"jrjackson" => "jr_jackson"}.freeze

    IDENTITY_LOADER = ->(adapter, _) { adapter }
    STRING_LOADER = ->(adapter, selector) { selector.send(:load_adapter_from_string_name, adapter) }
    SYMBOL_LOADER = ->(adapter, selector) { selector.send(:load_adapter_from_string_name, adapter.to_s) }
    DEFAULT_LOADER = ->(_, selector) { selector.send(:load_adapter, selector.default_adapter) }

    ADAPTER_LOADERS = {
      String => STRING_LOADER,
      Symbol => SYMBOL_LOADER,
      NilClass => DEFAULT_LOADER,
      FalseClass => DEFAULT_LOADER
    }.freeze

    def default_adapter
      @default_adapter ||= loaded_adapter || installable_adapter || fallback_adapter
    end

    private

    def fallback_adapter
      unless @default_adapter_warning_shown
        Kernel.warn(
          "[WARNING] MultiJson is using the default adapter (ok_json). " \
          "We recommend loading a different JSON library to improve performance."
        )
        @default_adapter_warning_shown = true
      end
      :ok_json
    end

    def load_adapter(new_adapter)
      loader = adapter_loader_for(new_adapter)
      return loader.call(new_adapter, self) if loader

      raise ::LoadError, new_adapter
    rescue ::LoadError => e
      raise AdapterError.build(e)
    end

    def adapter_loader_for(adapter)
      ADAPTER_LOADERS[adapter.class] || module_loader_if_module(adapter)
    end

    def module_loader_if_module(adapter)
      IDENTITY_LOADER if adapter.is_a?(::Module)
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
      ::MultiJson::REQUIREMENT_MAP.each do |adapter, library|
        require library
        return adapter
      rescue ::LoadError
        # ignore and try next
      end
      nil
    end

    def load_adapter_from_string_name(name)
      normalized_name = ALIASES.fetch(name, name)
      require_relative "adapters/#{normalized_name.downcase}"
      klass_name = normalized_name.split("_").map(&:capitalize).join
      ::MultiJson::Adapters.const_get(klass_name)
    end
  end
end
