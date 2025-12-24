require "bundler/setup"

unless ENV["MUTANT"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"
    # Oj v2 compatibility code - cannot be tested with Oj v3
    add_filter "lib/multi_json/adapters/oj_common.rb"
    # JrJackson arity compatibility code - only one branch can run per version
    add_filter "lib/multi_json/adapters/jr_jackson.rb"

    # JRuby doesn't support branch coverage
    if RUBY_PLATFORM == "java"
      minimum_coverage line: 100
    else
      enable_coverage :branch
      minimum_coverage line: 100, branch: 100
    end
  end
end

require "multi_json"
require "minitest/autorun"
require "mutant/minitest/coverage"

module TestHelpers
  module_function

  def adapter_available?(name)
    Gem.loaded_specs.key?(name.to_s)
  end

  def java?
    RUBY_PLATFORM == "java"
  end

  def oj? = adapter_available?(:oj)
  def yajl? = adapter_available?(:yajl)
  def json? = adapter_available?(:json)
  def ok_json? = adapter_available?(:ok_json)
  def fast_jsonparser? = adapter_available?(:fast_jsonparser)
  def gson? = adapter_available?(:gson)
  def jrjackson? = adapter_available?(:jrjackson)

  def silence_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  def undefine_constants(*consts)
    original_values = consts.each_with_object({}) do |const, hash|
      hash[const] = Object.const_get(const) if Object.const_defined?(const)
    end
    original_values.each_key { |const| Object.send(:remove_const, const) }
    yield
  ensure
    original_values.each { |const, value| Object.const_set(const, value) unless Object.const_defined?(const) }
  end

  def break_requirements(&)
    replacements = MultiJson::REQUIREMENT_MAP.transform_values { |library| "foo/#{library}" }
    stub_constant(MultiJson, :REQUIREMENT_MAP, replacements, &)
  end

  def stub_constant(mod, const_name, value)
    original = mod.const_get(const_name)
    mod.send(:remove_const, const_name)
    mod.const_set(const_name, value)
    yield
  ensure
    mod.send(:remove_const, const_name)
    mod.const_set(const_name, original)
  end

  def simulate_no_adapters(&block)
    break_requirements { undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser, &block) }
  end

  def get_exception(exception_class = StandardError)
    yield
    nil
  rescue exception_class => e
    e
  end

  def with_default_options
    adapter = MultiJson.adapter
    adapter.load_options = adapter.dump_options = MultiJson.load_options = MultiJson.dump_options = nil
    yield
  ensure
    adapter.load_options = adapter.dump_options = MultiJson.load_options = MultiJson.dump_options = nil
  end

  def with_stub(object, method_name, replacement, call_original: false)
    original = object.method(method_name)
    metaclass = class << object; self; end
    define_stub_method(metaclass, method_name, replacement, original, call_original)
    yield
  ensure
    silence_warnings { metaclass.define_method(method_name, original) }
  end

  def define_stub_method(metaclass, method_name, replacement, original, call_original)
    silence_warnings do
      if call_original
        metaclass.define_method(method_name) do |*a, **k, &b|
          replacement.call(*a, **k, &b)
          original.call(*a, **k, &b)
        end
      else
        metaclass.define_method(method_name, replacement)
      end
    end
  end

  def clear_default_adapter_warning
    return unless MultiJson.instance_variable_defined?(:@default_adapter_warning_shown)

    MultiJson.remove_instance_variable(:@default_adapter_warning_shown)
  end

  # Custom adapter that verifies exact argument signatures
  class StrictAdapter
    class ParseError < StandardError; end

    class << self
      attr_accessor :load_calls, :dump_calls

      def reset_calls
        @load_calls = []
        @dump_calls = []
      end

      def load(string, options = nil)
        raise ArgumentError, "load requires exactly 2 arguments" if options.nil?
        raise ArgumentError, "string cannot be nil" if string.nil?

        @load_calls ||= []
        @load_calls << {string: string, options: options}

        return symbolize_keys(::JSON.parse(string)) if options[:symbolize_keys]

        ::JSON.parse(string)
      rescue ::JSON::ParserError => e
        raise ParseError, e.message
      end

      def dump(object, options = nil)
        raise ArgumentError, "dump requires exactly 2 arguments" if options.nil?
        raise ArgumentError, "object cannot be nil" if object.nil?

        @dump_calls ||= []
        @dump_calls << {object: object, options: options}
        ::JSON.generate(object)
      end

      private

      def symbolize_keys(hash)
        return hash unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(k, v), h|
          h[k.to_sym] = symbolize_keys(v)
        end
      end
    end
  end

  def expected_default_adapter
    if java? && jrjackson? then "MultiJson::Adapters::JrJackson"
    elsif java? && json? then "MultiJson::Adapters::JsonGem"
    elsif fast_jsonparser? then "MultiJson::Adapters::FastJsonparser"
    else
      "MultiJson::Adapters::Oj"
    end
  end

  def track_current_adapter_options(&)
    adapter = nil
    stub = ->(opts = {}) { adapter = opts[:adapter] if opts.is_a?(Hash) }
    with_stub(MultiJson, :current_adapter, stub, call_original: true, &)
    adapter
  end
end

module Minitest
  class Test
    include TestHelpers
  end
end
