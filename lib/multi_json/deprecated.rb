# Deprecated public API kept around for one major release
#
# Each method here emits a one-time deprecation warning on first call and
# delegates to its current-API counterpart. The whole file is loaded by
# {MultiJson} so the deprecation surface stays out of the main module
# definition.
#
# @api private
module MultiJson
  # Set default options for both load and dump operations
  #
  # @api private
  # @deprecated Use {.load_options=} and {.dump_options=} instead
  # @param value [Hash] options hash
  # @return [Hash] the options hash
  # @example
  #   MultiJson.default_options = {symbolize_keys: true}
  def self.default_options=(value)
    warn_deprecation_once(:default_options=,
      "MultiJson.default_options setter is deprecated\n" \
      "Use MultiJson.load_options and MultiJson.dump_options instead")
    self.load_options = self.dump_options = value
  end

  # Get the default options
  #
  # @api private
  # @deprecated Use {.load_options} or {.dump_options} instead
  # @return [Hash] the current load options
  # @example
  #   MultiJson.default_options  #=> {}
  def self.default_options
    warn_deprecation_once(:default_options,
      "MultiJson.default_options is deprecated\n" \
      "Use MultiJson.load_options or MultiJson.dump_options instead")
    load_options
  end

  # @deprecated These methods are no longer used
  %w[cached_options reset_cached_options!].each do |method_name|
    define_singleton_method(method_name) do |*|
      message = "MultiJson.#{method_name} method is deprecated and no longer used."
      warn_deprecation_once(method_name.to_sym, message)
    end
  end

  # Returns the default adapter name (deprecated alias for default_adapter)
  #
  # @api public
  # @deprecated Use {.default_adapter} instead. Will be removed in v2.0.
  # @return [Symbol] the default adapter name
  # @example
  #   MultiJson.default_engine  #=> :oj
  def self.default_engine
    warn_deprecation_once(:default_engine,
      "MultiJson.default_engine is deprecated and will be removed in v2.0. " \
      "Use MultiJson.default_adapter instead.")
    default_adapter
  end

  # Returns the current adapter class (deprecated alias for adapter)
  #
  # @api private
  # @deprecated Use {.adapter} instead. Will be removed in v2.0.
  # @return [Class] the current adapter class
  # @example
  #   MultiJson.engine  #=> MultiJson::Adapters::Oj
  def self.engine
    warn_deprecation_once(:engine,
      "MultiJson.engine is deprecated and will be removed in v2.0. " \
      "Use MultiJson.adapter instead.")
    adapter
  end

  # Sets the adapter to use for JSON operations (deprecated)
  #
  # @api private
  # @deprecated Use {.adapter=} instead. Will be removed in v2.0.
  # @param new_adapter [Symbol, String, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.engine = :json_gem
  def self.engine=(new_adapter)
    warn_deprecation_once(:engine=,
      "MultiJson.engine= is deprecated and will be removed in v2.0. " \
      "Use MultiJson.adapter= instead.")
    use(new_adapter)
  end

  # Parses a JSON string into a Ruby object (deprecated alias for load)
  #
  # @api private
  # @deprecated Use {.load} instead. Will be removed in v2.0.
  # @param string [String, #read] JSON string or IO-like object
  # @param options [Hash] parsing options (adapter-specific)
  # @return [Object] parsed Ruby object
  # @example
  #   MultiJson.decode('{"foo":"bar"}')  #=> {"foo" => "bar"}
  def self.decode(string, options = {})
    warn_deprecation_once(:decode,
      "MultiJson.decode is deprecated and will be removed in v2.0. " \
      "Use MultiJson.load instead.")
    load(string, options)
  end

  # Serializes a Ruby object to a JSON string (deprecated alias for dump)
  #
  # @api private
  # @deprecated Use {.dump} instead. Will be removed in v2.0.
  # @param object [Object] object to serialize
  # @param options [Hash] serialization options (adapter-specific)
  # @return [String] JSON string
  # @example
  #   MultiJson.encode({foo: "bar"})  #=> '{"foo":"bar"}'
  def self.encode(object, options = {})
    warn_deprecation_once(:encode,
      "MultiJson.encode is deprecated and will be removed in v2.0. " \
      "Use MultiJson.dump instead.")
    dump(object, options)
  end

  # Executes a block using the specified adapter (deprecated alias for with_adapter)
  #
  # @api private
  # @deprecated Use {.with_adapter} instead. Will be removed in v2.0.
  # @param new_adapter [Symbol, String, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   MultiJson.with_engine(:json_gem) { MultiJson.dump({}) }
  def self.with_engine(new_adapter, &)
    warn_deprecation_once(:with_engine,
      "MultiJson.with_engine is deprecated and will be removed in v2.0. " \
      "Use MultiJson.with_adapter instead.")
    with_adapter(new_adapter, &)
  end

  private

  # Instance-method delegate for the deprecated default_options setter
  #
  # @api private
  # @deprecated Use {MultiJson.load_options=} and {MultiJson.dump_options=} instead
  # @param value [Hash] options hash
  # @return [Hash] the options hash
  # @example
  #   class Foo; include MultiJson; end
  #   Foo.new.send(:default_options=, symbolize_keys: true)
  def default_options=(value)
    MultiJson.default_options = value
  end

  # Instance-method delegate for the deprecated default_options getter
  #
  # @api private
  # @deprecated Use {MultiJson.load_options} or {MultiJson.dump_options} instead
  # @return [Hash] the current load options
  # @example
  #   class Foo; include MultiJson; end
  #   Foo.new.send(:default_options)
  def default_options
    MultiJson.default_options
  end
end
