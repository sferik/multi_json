module MultiJson
  module AdapterSelector
    module_function

    ALIASES = {"jrjackson" => "jr_jackson"}.freeze

    def default_adapter
      adapter = loaded_adapter || installable_adapter
      return adapter if adapter

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
      case new_adapter
      when String, Symbol then load_adapter_from_string_name new_adapter.to_s
      when NilClass, FalseClass then load_adapter default_adapter
      when Class, Module then new_adapter
      else raise ::LoadError, new_adapter
      end
    rescue ::LoadError => e
      raise(AdapterError.build(e), cause: e)
    end

    def loaded_adapter
      return :fast_jsonparser if defined?(::FastJsonparser)
      return :oj if defined?(::Oj)
      return :yajl if defined?(::Yajl)
      return :jr_jackson if defined?(::JrJackson)
      return :json_gem if defined?(::JSON::Ext::Parser)
      return :gson if defined?(::Gson)

      nil
    end

    def installable_adapter
      MultiJson::REQUIREMENT_MAP.each do |adapter, library|
        require library
        return adapter
      rescue ::LoadError
        next
      end
      nil
    end

    def load_adapter_from_string_name(name)
      normalized_name = ALIASES.fetch(name, name).to_s
      require "multi_json/adapters/#{normalized_name.downcase}"
      klass_name = normalized_name.split("_").map(&:capitalize).join
      MultiJson::Adapters.const_get(klass_name)
    end
  end
end
