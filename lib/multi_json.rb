# frozen_string_literal: true

require_relative "multi_json/concurrency"
require_relative "multi_json/options"
require_relative "multi_json/version"
require_relative "multi_json/adapter_error"
require_relative "multi_json/parse_error"
require_relative "multi_json/options_cache"
require_relative "multi_json/adapter_selector"
require_relative "multi_json/adapter_overrides"
require_relative "multi_json/adapter_state_helpers"

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
  extend AdapterOverrides
  extend AdapterStateHelpers

  # Resolve the ``ParseError`` constant for an adapter class
  #
  # The result is memoized on the adapter class itself in a
  # ``@_multi_json_parse_error`` ivar so subsequent ``MultiJSON.parse``
  # calls skip the constant lookup entirely. The lookup is performed
  # with ``inherit: false`` so a stray top-level ``::ParseError``
  # constant in the host process is correctly ignored on every
  # supported Ruby implementation.
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

  # Returns the current parse adapter class
  #
  # Backwards-compatible alias for {.parse_adapter}.
  #
  # @api public
  # @return [Class] the current parse adapter class
  # @example
  #   MultiJSON.adapter  #=> MultiJSON::Adapters::Oj
  def self.adapter
    parse_adapter
  end

  # Returns the current parse adapter class
  #
  # Honors fiber-local overrides set by {.with_adapter} so concurrent
  # blocks observe their own adapter without clobbering the process-wide
  # default. Falls back to the parse-side process default when no
  # override is set.
  #
  # @api public
  # @return [Class] the current parse adapter class
  # @example
  #   MultiJSON.parse_adapter  #=> MultiJSON::Adapters::Oj
  def self.parse_adapter
    override = Fiber[:multi_json_parse_adapter] || Fiber[:multi_json_adapter]
    return override if override

    @parse_adapter ||= load_adapter(default_parse_adapter)
  end

  # Returns the current generate adapter class
  #
  # Honors fiber-local overrides set by {.with_adapter} so concurrent
  # blocks observe their own adapter without clobbering the process-wide
  # default. Falls back to the generate-side process default when no
  # override is set.
  #
  # @api public
  # @return [Class] the current generate adapter class
  # @example
  #   MultiJSON.generate_adapter  #=> MultiJSON::Adapters::JsonGem
  def self.generate_adapter
    override = Fiber[:multi_json_generate_adapter] || Fiber[:multi_json_adapter]
    return override if override

    @generate_adapter ||= load_adapter(default_generate_adapter)
  end

  # Sets the adapter to use for both JSON operations
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
    parse_loaded = resolve_adapter_or_default(new_adapter, :parse)
    generate_loaded =
      if default_adapter_spec?(new_adapter)
        resolve_adapter_or_default(new_adapter, :generate)
      else
        parse_loaded
      end

    store_directional_adapters(parse_loaded, generate_loaded)
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

  # Sets the adapter to use for parse operations
  #
  # Passing ``nil`` resets parsing to the auto-detected parse default.
  #
  # @api public
  # @param new_adapter [Symbol, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJSON.parse_adapter = :jr_jackson
  def self.parse_adapter=(new_adapter)
    loaded = resolve_adapter_or_default(new_adapter, :parse)
    store_parse_adapter(loaded)
  end

  # Sets the adapter to use for generate operations
  #
  # Passing ``nil`` resets generation to the auto-detected generate default.
  #
  # @api public
  # @param new_adapter [Symbol, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJSON.generate_adapter = :json_gem
  def self.generate_adapter=(new_adapter)
    loaded = resolve_adapter_or_default(new_adapter, :generate)
    store_generate_adapter(loaded)
  end

  # Parses a JSON string into a Ruby object
  #
  # Raises {ParseError} on blank, whitespace-only, and ``nil``
  # inputs, matching Ruby stdlib ``JSON.parse`` and RFC 8259 (which
  # defines empty input as invalid JSON).
  #
  # @api public
  # @param string [String, #read] JSON string or IO-like object
  # @param symbolize_names [Boolean] return symbol keys instead of string keys
  # @param adapter [Symbol, Module, nil] one-shot adapter override
  # @param opts [Hash] additional adapter-specific parsing options
  # @return [Object] parsed Ruby object
  # @raise [ParseError] if parsing fails or the input is blank or nil
  # @raise [AdapterError] if the adapter doesn't define a ``ParseError`` constant
  # @example
  #   MultiJSON.parse('{"foo":"bar"}')                        #=> {"foo" => "bar"}
  #   MultiJSON.parse('{"foo":"bar"}', symbolize_names: true) #=> {foo: "bar"}
  #   MultiJSON.parse("")                                     # raises MultiJSON::ParseError
  #   MultiJSON.parse(nil)                                    # raises MultiJSON::ParseError
  def self.parse(string, symbolize_names: false, adapter: nil, **opts)
    opts[:symbolize_names] = symbolize_names if symbolize_names
    opts[:adapter] = adapter if adapter
    adapter_class = current_adapter(**opts)
    parse_error_class = parse_error_class_for(adapter_class)
    begin
      adapter_class.parse(string, opts)
    rescue parse_error_class => e
      raise ParseError.build(e, string)
    end
  end

  # Returns the parse adapter to use for the given options
  #
  # @api public
  # @param options [Hash] optional kwargs; only ``:adapter`` is consulted
  # @return [Class] adapter class
  # @example
  #   MultiJSON.current_adapter(adapter: :oj)  #=> MultiJSON::Adapters::Oj
  def self.current_adapter(options = nil, adapter: nil, **)
    adapter_override = options[:adapter] if options.is_a?(Hash)
    adapter_override ||= adapter
    adapter_override ? load_adapter(adapter_override) : self.adapter
  end

  # Returns the parse adapter to use for the given options
  #
  # @api public
  # @param adapter [Symbol, Module, nil] one-shot parse adapter override
  # @param _opts [Hash] ignored adapter-specific options
  # @return [Class] adapter class
  # @example
  #   MultiJSON.current_parse_adapter(adapter: :oj)  #=> MultiJSON::Adapters::Oj
  def self.current_parse_adapter(options = nil, adapter: nil, **_opts)
    adapter = options[:adapter] if options.is_a?(Hash) && adapter.nil?
    adapter ? load_adapter(adapter) : parse_adapter
  end

  # Returns the generate adapter to use for the given options
  #
  # @api public
  # @param adapter [Symbol, Module, nil] one-shot generate adapter override
  # @param _opts [Hash] ignored adapter-specific options
  # @return [Class] adapter class
  # @example
  #   MultiJSON.current_generate_adapter(adapter: :json_gem)  #=> MultiJSON::Adapters::JsonGem
  def self.current_generate_adapter(options = nil, adapter: nil, **_opts)
    adapter = options[:adapter] if options.is_a?(Hash) && adapter.nil?
    adapter ? load_adapter(adapter) : generate_adapter
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
  #   MultiJSON.generate({foo: "bar"})               #=> '{"foo":"bar"}'
  #   MultiJSON.generate({foo: "bar"}, pretty: true) #=> "{\n  \"foo\": \"bar\"\n}"
  def self.generate(object, pretty: false, adapter: nil, **opts)
    opts[:pretty] = pretty if pretty
    opts[:adapter] = adapter if adapter
    adapter_class = adapter ? current_adapter(**opts) : current_generate_adapter(**opts)
    adapter_class.generate(object, opts)
  end
end
