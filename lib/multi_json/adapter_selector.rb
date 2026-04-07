module MultiJson
  # Handles adapter discovery, loading, and selection
  #
  # Adapters can be specified as:
  # - Symbol/String: adapter name (e.g., :oj, "json_gem")
  # - Module: adapter class directly
  # - nil/false: use default adapter
  #
  # @api private
  module AdapterSelector
    extend self

    # Alternate spellings for adapter names
    ALIASES = {"jrjackson" => "jr_jackson"}.freeze

    # Maps adapter symbols to their require paths for auto-loading
    REQUIREMENT_MAP = {
      fast_jsonparser: "fast_jsonparser",
      oj: "oj",
      yajl: "yajl",
      jr_jackson: "jrjackson",
      json_gem: "json",
      gson: "gson"
    }.freeze

    # Returns the default adapter to use
    #
    # @api private
    # @return [Symbol] adapter name
    # @example
    #   AdapterSelector.default_adapter  #=> :oj
    def default_adapter
      @default_adapter ||= detect_best_adapter
    end

    private

    # Detects the best available JSON adapter
    #
    # @api private
    # @return [Symbol] adapter name
    def detect_best_adapter
      loaded_adapter || installable_adapter || fallback_adapter
    end

    # Finds an already-loaded JSON library
    #
    # @api private
    # @return [Symbol, nil] adapter name if found
    def loaded_adapter
      return :fast_jsonparser if defined?(::FastJsonparser)
      return :oj if defined?(::Oj)
      return :yajl if defined?(::Yajl)
      return :jr_jackson if defined?(::JrJackson)
      return :json_gem if defined?(::JSON::Ext::Parser)

      :gson if defined?(::Gson)
    end

    # Tries to require and use an installable adapter
    #
    # @api private
    # @return [Symbol, nil] adapter name if successfully required
    def installable_adapter
      REQUIREMENT_MAP.each_key do |adapter_name|
        return adapter_name if try_require(adapter_name)
      end
      nil
    end

    # Attempts to require a JSON library
    #
    # @api private
    # @param adapter_name [Symbol] adapter to require
    # @return [Boolean] true if require succeeded
    def try_require(adapter_name)
      require REQUIREMENT_MAP.fetch(adapter_name)
      true
    rescue ::LoadError
      false
    end

    # Returns the fallback adapter when no others available
    #
    # @api private
    # @return [Symbol] the ok_json adapter name
    def fallback_adapter
      warn_about_fallback unless @default_adapter_warning_shown
      @default_adapter_warning_shown = true
      :ok_json
    end

    # Warns the user about using the slow fallback adapter
    #
    # @api private
    # @return [void]
    def warn_about_fallback
      Kernel.warn(
        "[WARNING] MultiJson is using the default adapter (ok_json). " \
        "We recommend loading a different JSON library to improve performance."
      )
    end

    # Loads an adapter from a specification
    #
    # @api private
    # @param adapter_spec [Symbol, String, Module, nil, false] adapter specification
    # @return [Class] the adapter class
    def load_adapter(adapter_spec)
      case adapter_spec
      when ::String then load_adapter_by_name(adapter_spec)
      when ::Symbol then load_adapter_by_name(adapter_spec.to_s)
      when nil, false then load_adapter(default_adapter)
      when ::Module then adapter_spec
      else raise ::LoadError, adapter_spec
      end
    rescue ::LoadError => e
      raise AdapterError.build(e)
    end

    # Loads an adapter by its string name
    #
    # @api private
    # @param name [String] adapter name
    # @return [Class] the adapter class
    def load_adapter_by_name(name)
      normalized = ALIASES.fetch(name, name).downcase
      require_relative "adapters/#{normalized}"

      class_name = normalized.split("_").map(&:capitalize).join
      ::MultiJson::Adapters.const_get(class_name)
    end
  end
end
