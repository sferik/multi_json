require_relative "multi_json/options"
require_relative "multi_json/version"
require_relative "multi_json/adapter_error"
require_relative "multi_json/parse_error"
require_relative "multi_json/options_cache"
require_relative "multi_json/adapter_selector"

# A unified interface for JSON libraries in Ruby
#
# MultiJson allows swapping between JSON backends without changing your code.
# It auto-detects available JSON libraries and uses the fastest one available.
#
# ## Method-definition patterns
#
# The public API uses two patterns, each chosen for a specific reason:
#
# 1. ``module_function`` creates both a class method and a private instance
#    method from a single ``def``. This is used for the hot-path API
#    (``adapter``, ``use``, ``adapter=``, ``load``, ``dump``,
#    ``current_adapter``) so that both ``MultiJson.load(...)`` and legacy
#    ``Class.new { include MultiJson }.new.send(:load, ...)`` invocations
#    work through the same body. The instance versions are re-publicized
#    below so YARD renders them as part of the public API.
# 2. ``def self.foo`` creates only a singleton method, giving mutation
#    testing a single canonical definition to target. This is used for
#    deprecated methods (``decode``, ``encode``, ``engine``, etc.) and
#    for {.with_adapter}, which needs precise mutation coverage of its
#    fiber-local save/restore logic. Private instance-method delegates
#    for the handful of ``def self.foo`` methods that are still tested
#    via ``obj.send(:foo)`` are added at the bottom of this module.
#
# @example Basic usage
#   MultiJson.load('{"foo":"bar"}')  #=> {"foo" => "bar"}
#   MultiJson.dump({foo: "bar"})     #=> '{"foo":"bar"}'
#
# @example Specifying an adapter
#   MultiJson.use(:oj)
#   MultiJson.load('{"foo":"bar"}', adapter: :json_gem)
#
# @api public
module MultiJson # rubocop:disable Metrics/ModuleLength
  extend Options
  extend AdapterSelector

  # Tracks which deprecation warnings have already been emitted so each one
  # fires at most once per process. Stored as a Set rather than a Hash so
  # presence checks have unambiguous semantics for mutation tests.
  DEPRECATION_WARNINGS_SHOWN = Set.new
  private_constant :DEPRECATION_WARNINGS_SHOWN

  # Mutex guarding {DEPRECATION_WARNINGS_SHOWN}. The check-then-add pair in
  # {warn_deprecation_once} would otherwise race under concurrent fibers or
  # threads, allowing two callers to both pass the membership check and emit
  # the same warning twice.
  DEPRECATION_WARNINGS_MUTEX = Mutex.new
  private_constant :DEPRECATION_WARNINGS_MUTEX

  class << self
    private

    # Emit a deprecation warning at most once per process for the given key
    #
    # Defined as a singleton method (rather than via module_function) so
    # there is exactly one definition for mutation tests to target. The
    # deprecated method bodies invoke this via ``warn_deprecation_once(...)``
    # (singleton callers) and via the private instance delegates routing
    # through the singleton for legacy ``include MultiJson`` consumers.
    #
    # @api private
    # @param key [Symbol] identifier for the deprecation (typically the method name)
    # @param message [String] warning message to emit on first call
    # @return [void]
    # @example
    #   MultiJson.send(:warn_deprecation_once, :foo, "MultiJson.foo is deprecated")
    def warn_deprecation_once(key, message)
      DEPRECATION_WARNINGS_MUTEX.synchronize do
        return if DEPRECATION_WARNINGS_SHOWN.include?(key)

        Kernel.warn(message)
        DEPRECATION_WARNINGS_SHOWN.add(key)
      end
    end
  end

  # ===========================================================================
  # Public API (module_function: class + private instance method)
  # ===========================================================================

  # @!visibility private
  module_function

  # Returns the current adapter class
  #
  # Honors a fiber-local override set by {.with_adapter} so concurrent
  # blocks observe their own adapter without clobbering the process-wide
  # default. Falls back to the process default when no override is set.
  #
  # @api public
  # @return [Class] the current adapter class
  # @example
  #   MultiJson.adapter  #=> MultiJson::Adapters::Oj
  def adapter
    override = Fiber[:multi_json_adapter]
    return override if override

    @adapter ||= use(nil)
  end

  # Sets the adapter to use for JSON operations
  #
  # The merged-options cache is only reset when the new adapter loads
  # successfully. A failed ``use(:nonexistent)`` leaves the cache in
  # place so the previously-active adapter keeps its cached entries.
  #
  # @api public
  # @param new_adapter [Symbol, String, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.use(:oj)
  def use(new_adapter)
    loaded = load_adapter(new_adapter)
    OptionsCache.reset
    @adapter = loaded
  end

  # Sets the adapter to use for JSON operations
  #
  # @api public
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.adapter = :json_gem
  alias_method :adapter=, :use
  module_function :adapter=

  # Parses a JSON string into a Ruby object
  #
  # @api public
  # @param string [String, #read] JSON string or IO-like object
  # @param options [Hash] parsing options (adapter-specific)
  # @return [Object] parsed Ruby object
  # @raise [ParseError] if parsing fails
  # @example
  #   MultiJson.load('{"foo":"bar"}')  #=> {"foo" => "bar"}
  def load(string, options = {})
    adapter_class = current_adapter(options)
    adapter_class.load(string, options)
  rescue adapter_class::ParseError => e
    raise ParseError.build(e, string)
  end

  # Returns the adapter to use for the given options
  #
  # @api public
  # @param options [Hash] options that may contain :adapter key
  # @return [Class] adapter class
  # @example
  #   MultiJson.current_adapter(adapter: :oj)  #=> MultiJson::Adapters::Oj
  def current_adapter(options = {})
    options ||= {}
    adapter_override = options[:adapter]
    adapter_override ? load_adapter(adapter_override) : adapter
  end

  # Serializes a Ruby object to a JSON string
  #
  # @api public
  # @param object [Object] object to serialize
  # @param options [Hash] serialization options (adapter-specific)
  # @return [String] JSON string
  # @example
  #   MultiJson.dump({foo: "bar"})  #=> '{"foo":"bar"}'
  def dump(object, options = {})
    current_adapter(options).dump(object, options)
  end

  # Re-publicize the instance versions of the module_function methods so
  # YARD/yardstick render them as part of the public API and legacy
  # ``include MultiJson`` consumers can call them without ``.send``.
  public :adapter, :use, :adapter=, :load, :current_adapter, :dump

  # ===========================================================================
  # Public API (def self.foo: singleton-only, for mutation-test precision)
  # ===========================================================================

  # Executes a block using the specified adapter
  #
  # Defined as a singleton method so mutation testing has exactly one
  # definition to target. The override is stored in fiber-local storage
  # so concurrent fibers and threads each see their own adapter without
  # racing on a shared module variable; nested calls save and restore
  # the previous fiber-local value.
  #
  # @api public
  # @param new_adapter [Symbol, String, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   MultiJson.with_adapter(:json_gem) { MultiJson.dump({}) }
  def self.with_adapter(new_adapter)
    previous_override = Fiber[:multi_json_adapter]
    Fiber[:multi_json_adapter] = load_adapter(new_adapter)
    yield
  ensure
    Fiber[:multi_json_adapter] = previous_override
  end

  # ===========================================================================
  # Deprecated class methods (def self.foo: singleton-only)
  # ===========================================================================

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

  # ===========================================================================
  # Private instance-method delegates for the singleton-only methods above
  # ===========================================================================

  private

  # Instance-method delegate for {MultiJson.with_adapter}
  #
  # @api private
  # @param new_adapter [Symbol, String, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   class Foo; include MultiJson; end
  #   Foo.new.send(:with_adapter, :json_gem) { ... }
  def with_adapter(new_adapter, &)
    MultiJson.with_adapter(new_adapter, &)
  end

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
