# frozen_string_literal: true

module MultiJSON
  # Handles adapter discovery, loading, and selection
  #
  # Adapters can be specified as:
  # - Symbol: adapter name (e.g., :oj, :json_gem)
  # - Module: adapter class directly
  # - nil/false: use default adapter
  #
  # @api private
  module AdapterSelector
    extend self

    # Parse adapter preference order (fastest first), used for
    # auto-detection on the parse path. JRuby's available adapter set
    # differs from MRI's, and the bundled benchmark suite ranks
    # json_gem ahead of fast_jsonparser/oj/yajl on Ruby 3.4+ — so the
    # list is split per platform to keep the "fastest first" promise
    # honest on each runtime. CI re-runs the benchmark with
    # ``--verify-preference`` to fail if the observed ranking diverges.
    # :nocov:
    PARSE_ADAPTERS = if RUBY_ENGINE == "jruby"
      %i[jr_jackson json_gem gson fast_jsonparser oj yajl].freeze
    else
      %i[json_gem fast_jsonparser oj yajl jr_jackson gson].freeze
    end
    # :nocov:
    GENERATE_ADAPTERS = %i[json_gem oj yajl jr_jackson gson].freeze
    private_constant :PARSE_ADAPTERS, :GENERATE_ADAPTERS

    # Per-adapter metadata. Each entry maps the adapter symbol to its
    # ``require`` path and the constant whose presence indicates the
    # backing library is already loaded. ``loaded`` is a ``::``-separated
    # path so we can walk it without an explicit ``defined?`` check.
    # PARSE_ADAPTERS / GENERATE_ADAPTERS drive the preference order, so
    # this hash's iteration order doesn't matter at runtime.
    ADAPTERS = {
      fast_jsonparser: {require: "fast_jsonparser", loaded: "FastJsonparser"},
      oj: {require: "oj", loaded: "Oj"},
      yajl: {require: "yajl", loaded: "Yajl"},
      jr_jackson: {require: "jrjackson", loaded: "JrJackson"},
      json_gem: {require: "json", loaded: "JSON::Ext::Parser"},
      gson: {require: "gson", loaded: "Gson"}
    }.freeze
    private_constant :ADAPTERS

    # Backwards-compatible view of {ADAPTERS} that exposes only the
    # require paths. Tests still poke at this constant to stub or break
    # the require step.
    REQUIREMENT_MAP = ADAPTERS.transform_values { |meta| meta[:require] }.freeze

    private

    # Detects the best available JSON adapter for an operation
    #
    # @api private
    # @param operation [Symbol] :parse or :generate
    # @return [Symbol] adapter name
    def detect_best_adapter(operation)
      preferences = adapter_preferences(operation)
      installable_adapter(preferences) || loaded_adapter(preferences) || fallback_adapter
    end

    # Finds an already-loaded JSON library
    #
    # @api private
    # @param preferences [Array<Symbol>] adapter preference order
    # @param excluding [Symbol, nil] adapter name to skip during detection
    # @return [Symbol, nil] adapter name if found
    def loaded_adapter(preferences = PARSE_ADAPTERS, excluding: nil)
      preferences.each do |name|
        next if name == excluding

        meta = ADAPTERS.fetch(name)
        return name if Object.const_defined?(meta.fetch(:loaded))
      end
      nil
    end

    # Tries to require and use an installable adapter
    #
    # @api private
    # @param preferences [Array<Symbol>] adapter preference order
    # @param excluding [Symbol, nil] adapter name to skip during detection
    # @return [Symbol, nil] adapter name if successfully required
    def installable_adapter(preferences = PARSE_ADAPTERS, excluding: nil)
      preferences.each do |adapter_name|
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

    # Returns the preference order for an operation
    #
    # @api private
    # @param operation [Symbol] :parse or :generate
    # @return [Array<Symbol>] adapter preference order
    def adapter_preferences(operation)
      case operation
      when :parse then PARSE_ADAPTERS
      when :generate then GENERATE_ADAPTERS
      else raise ArgumentError, "expected operation to be :parse or :generate, got #{operation.inspect}"
      end
    end

    # Warns the user about reaching the last-resort fallback
    #
    # @api private
    # @return [void]
    def warn_about_fallback
      Kernel.warn(
        "[WARNING] MultiJSON is falling back to the json_gem adapter " \
        "because no other JSON library could be loaded."
      )
    end

    # Loads an adapter from a specification
    #
    # @api private
    # @param adapter_spec [Symbol, Module, nil, false] adapter specification
    # @return [Class] the adapter class
    def load_adapter(adapter_spec)
      adapter = case adapter_spec
      when ::Symbol then load_adapter_by_name(adapter_spec.to_s)
      when nil, false then load_adapter(default_adapter)
      when ::Module then adapter_spec
      else raise LoadError, "expected adapter to be a Symbol or Module, got #{adapter_spec.inspect}"
      end
      validate_adapter!(adapter)
    rescue LoadError => e
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
      ::MultiJSON::Adapters.const_get(class_name)
    end

    # Validate that an adapter satisfies the documented contract
    #
    # Custom adapters are accepted as modules/classes, so fail fast
    # during adapter resolution rather than later on the first parse
    # or generate call.
    #
    # @api private
    # @param adapter [Module] adapter class or module
    # @return [Module] the validated adapter
    # @raise [AdapterError] when the adapter is missing a required class method
    #   or ParseError constant
    def validate_adapter!(adapter)
      raise AdapterError, "Adapter #{adapter} must respond to .parse" unless adapter.respond_to?(:parse)
      raise AdapterError, "Adapter #{adapter} must respond to .generate" unless adapter.respond_to?(:generate)

      MultiJSON.parse_error_class_for(adapter)
      adapter
    end
  end
end

require_relative "adapter_selector/defaults"
