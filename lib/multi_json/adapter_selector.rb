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

    # Maps adapter symbols to their require paths for auto-loading.
    # Insertion order is the preference order used by adapter detection
    # (fastest first).
    REQUIREMENT_MAP = {
      fast_jsonparser: "fast_jsonparser",
      oj: "oj",
      yajl: "yajl",
      jr_jackson: "jrjackson",
      json_gem: "json",
      gson: "gson"
    }.freeze

    # Callable detectors paired with adapter symbols, in the same
    # preference order as REQUIREMENT_MAP. Each lambda returns truthy
    # when its adapter's backing library is already loaded.
    LOADED_ADAPTER_DETECTORS = {
      fast_jsonparser: -> { defined?(::FastJsonparser) },
      oj: -> { defined?(::Oj) },
      yajl: -> { defined?(::Yajl) },
      jr_jackson: -> { defined?(::JrJackson) },
      json_gem: -> { defined?(::JSON::Ext::Parser) },
      gson: -> { defined?(::Gson) }
    }.freeze
    private_constant :LOADED_ADAPTER_DETECTORS

    # Returns the default adapter to use
    #
    # @api private
    # @return [Symbol] adapter name
    # @example
    #   AdapterSelector.default_adapter  #=> :oj
    def default_adapter
      @default_adapter ||= detect_best_adapter
    end

    # Returns the default adapter class, excluding the given adapter name
    #
    # Used by adapters that only implement one direction (e.g.
    # FastJsonparser only parses) so the other direction can be delegated
    # to whichever library MultiJson would otherwise pick.
    #
    # @api private
    # @param excluded [Symbol] adapter name to skip during detection
    # @return [Class] the adapter class
    # @example
    #   AdapterSelector.default_adapter_excluding(:fast_jsonparser)  #=> MultiJson::Adapters::Oj
    def default_adapter_excluding(excluded)
      name = loaded_adapter(excluding: excluded)
      name ||= installable_adapter(excluding: excluded)
      name ||= fallback_adapter
      load_adapter_by_name(name.to_s)
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
    # @param excluding [Symbol, nil] adapter name to skip during detection
    # @return [Symbol, nil] adapter name if found
    def loaded_adapter(excluding: nil)
      LOADED_ADAPTER_DETECTORS.each do |name, detect|
        next if name == excluding
        return name if detect.call
      end
      nil
    end

    # Tries to require and use an installable adapter
    #
    # @api private
    # @param excluding [Symbol, nil] adapter name to skip during detection
    # @return [Symbol, nil] adapter name if successfully required
    def installable_adapter(excluding: nil)
      REQUIREMENT_MAP.each_key do |adapter_name|
        next if adapter_name == excluding
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
    # The json gem is a Ruby default gem since Ruby 1.9, so in practice
    # the installable-adapter step always succeeds before reaching this
    # fallback on any supported Ruby version. The warning below only
    # fires in tests that deliberately break the require path.
    #
    # @api private
    # @return [Symbol] the json_gem adapter name
    def fallback_adapter
      warn_about_fallback unless @default_adapter_warning_shown
      @default_adapter_warning_shown = true
      :json_gem
    end

    # Warns the user about reaching the last-resort fallback
    #
    # @api private
    # @return [void]
    def warn_about_fallback
      Kernel.warn(
        "[WARNING] MultiJson is falling back to the json_gem adapter " \
        "because no other JSON library could be loaded."
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
    # ``jrjackson`` (the JrJackson gem's name) is normalized to
    # ``jr_jackson`` (the adapter file/class name) for backwards
    # compatibility with the original gem-name alias.
    #
    # @api private
    # @param name [String] adapter name
    # @return [Class] the adapter class
    def load_adapter_by_name(name)
      normalized = name.downcase
      normalized = "jr_jackson" if normalized == "jrjackson"
      require_relative "adapters/#{normalized}"

      class_name = normalized.split("_").map(&:capitalize).join
      ::MultiJson::Adapters.const_get(class_name)
    end
  end
end
