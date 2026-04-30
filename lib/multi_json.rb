# frozen_string_literal: true

require_relative "multi_json/concurrency"
require_relative "multi_json/options"
require_relative "multi_json/version"
require_relative "multi_json/adapter_error"
require_relative "multi_json/parse_error"
require_relative "multi_json/options_cache"
require_relative "multi_json/adapter_selector"

# A unified interface for JSON libraries in Ruby
#
# MultiJSON allows swapping between JSON backends without changing your code.
# It auto-detects available JSON libraries and uses the fastest one available.
#
# @example Basic usage
#   MultiJSON.parse('{"foo":"bar"}')  #=> {"foo" => "bar"}
#   MultiJSON.generate({foo: "bar"})  #=> '{"foo":"bar"}'
#
# @example Specifying an adapter
#   MultiJSON.use(:oj)
#   MultiJSON.parse('{"foo":"bar"}', adapter: :json_gem)
#
# @api public
module MultiJSON
  extend Options
  extend AdapterSelector
  # Resolve the ``ParseError`` constant for an adapter class
  #
  # The result is memoized on the adapter class itself in a
  # ``@_multi_json_parse_error`` ivar so subsequent ``MultiJSON.parse``
  # calls skip the constant lookup entirely. The lookup is performed
  # with ``inherit: false`` so a stray top-level ``::ParseError``
  # constant in the host process is correctly ignored on every
  # supported Ruby implementation — TruffleRuby's ``::`` operator
  # walks the ancestor chain and would otherwise pick up the top-level
  # constant. Custom adapters that don't define their own
  # ``ParseError`` get a clear {AdapterError} instead of the bare
  # ``NameError`` Ruby would raise from the rescue clause.
  #
  # @api private
  # @param adapter_class [Class] adapter class to inspect
  # @return [Class] the adapter's ParseError class
  # @raise [AdapterError] when the adapter doesn't define ParseError
  def self.parse_error_class_for(adapter_class)
    cached = adapter_class.instance_variable_get(:@_multi_json_parse_error)
    return cached if cached

    resolved = adapter_class.const_get(:ParseError, false)
    adapter_class.instance_variable_set(:@_multi_json_parse_error, resolved)
  rescue NameError
    raise AdapterError, "Adapter #{adapter_class} must define a ParseError constant"
  end

  # Returns the current adapter class
  #
  # Honors a fiber-local override set by {.with_adapter} so concurrent
  # blocks observe their own adapter without clobbering the process-wide
  # default. Falls back to the process default when no override is set.
  #
  # @api public
  # @return [Class] the current adapter class
  # @example
  #   MultiJSON.adapter  #=> MultiJSON::Adapters::Oj
  def self.adapter
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
  # @param new_adapter [Symbol, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJSON.use(:oj)
  def self.use(new_adapter)
    loaded = load_adapter(new_adapter)
    Concurrency.synchronize(:adapter) do
      OptionsCache.reset
      @adapter = loaded
    end
  end

  class << self
    # Sets the adapter to use for JSON operations
    #
    # @api public
    # @return [Class] the loaded adapter class
    # @example
    #   MultiJSON.adapter = :json_gem
    alias_method :adapter=, :use
  end

  # Parses a JSON string into a Ruby object
  #
  # Returns ``nil`` for ``nil``, empty, and whitespace-only inputs
  # instead of raising. Pass an explicit non-blank string if you want
  # to surface a {ParseError} for empty payloads at the call site.
  #
  # @api public
  # @param string [String, #read] JSON string or IO-like object
  # @param symbolize_names [Boolean] return symbol keys instead of string keys
  # @param adapter [Symbol, Module, nil] one-shot adapter override
  # @param opts [Hash] additional adapter-specific parsing options
  # @return [Object, nil] parsed Ruby object, or nil for blank input
  # @raise [ParseError] if parsing fails
  # @raise [AdapterError] if the adapter doesn't define a ``ParseError`` constant
  # @example
  #   MultiJSON.parse('{"foo":"bar"}')                        #=> {"foo" => "bar"}
  #   MultiJSON.parse('{"foo":"bar"}', symbolize_names: true) #=> {foo: "bar"}
  #   MultiJSON.parse("")                                     #=> nil
  #   MultiJSON.parse("   \n")                                #=> nil
  def self.parse(string, symbolize_names: false, adapter: nil, **opts)
    opts[:symbolize_names] = symbolize_names if symbolize_names
    opts[:adapter] = adapter if adapter
    adapter_class = current_adapter(**opts)
    parse_error_class = parse_error_class_for(adapter_class)
    begin
      adapter_class.load(string, opts)
    rescue parse_error_class => e
      raise ParseError.build(e, string)
    end
  end

  # Returns the adapter to use for the given options
  #
  # @api public
  # @param options [Hash] optional kwargs; only ``:adapter`` is consulted
  # @return [Class] adapter class
  # @example
  #   MultiJSON.current_adapter(adapter: :oj)  #=> MultiJSON::Adapters::Oj
  def self.current_adapter(**options)
    override = options[:adapter]
    override ? load_adapter(override) : adapter
  end

  # Serializes a Ruby object to a JSON string
  #
  # @api public
  # @param object [Object] object to serialize
  # @param pretty [Boolean] format with indentation and newlines
  # @param adapter [Symbol, Module, nil] one-shot adapter override
  # @param opts [Hash] additional adapter-specific serialization options
  # @return [String] JSON string
  # @example
  #   MultiJSON.generate({foo: "bar"})                 #=> '{"foo":"bar"}'
  #   MultiJSON.generate({foo: "bar"}, pretty: true)   #=> "{\n  \"foo\": \"bar\"\n}"
  def self.generate(object, pretty: false, adapter: nil, **opts)
    opts[:pretty] = pretty if pretty
    opts[:adapter] = adapter if adapter
    current_adapter(**opts).dump(object, opts)
  end

  # Executes a block using the specified adapter
  #
  # The override is stored in fiber-local storage so concurrent fibers
  # and threads each see their own adapter without racing on a shared
  # module variable; nested calls save and restore the previous
  # fiber-local value.
  #
  # @api public
  # @param new_adapter [Symbol, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   MultiJSON.with_adapter(:json_gem) { MultiJSON.generate({}) }
  def self.with_adapter(new_adapter)
    # @type var previous_override: _Adapter | Module | nil
    previous_override = Fiber[:multi_json_adapter]
    Fiber[:multi_json_adapter] = load_adapter(new_adapter)
    yield
  ensure
    Fiber[:multi_json_adapter] = previous_override
  end
end
