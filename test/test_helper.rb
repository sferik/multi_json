# frozen_string_literal: true

require "bundler/setup"

unless ENV["MUTANT"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    # Oj v2 compatibility code - cannot be tested with Oj v3
    add_filter "lib/multi_json/adapters/oj_common.rb"

    case RUBY_ENGINE
    when "ruby"
      enable_coverage :branch
      minimum_coverage line: 100, branch: 100
    when "jruby"
      # JRuby's coverage backend doesn't support branch coverage, but line
      # coverage is still enforced at 100%.
      minimum_coverage line: 100
    else
      # TruffleRuby's coverage backend doesn't support branch coverage and
      # misses a handful of tail expressions and assignments that MRI counts
      # as covered, so the line threshold is relaxed for it as well.
      minimum_coverage line: 98
    end
  end
end

require "multi_json"
require "minitest/autorun"
require "mutant/minitest/coverage"
require_relative "support/strict_adapter"
require_relative "support/stub_helpers"

# Most test files declare ``cover "MultiJSON*"`` because the public API
# methods (load, dump, use, with_adapter, etc.) cross subject boundaries
# at runtime — a single MultiJSON.load call exercises MultiJSON.load,
# MultiJSON.current_adapter, MultiJSON::Adapter.load, and the underlying
# adapter's instance #load. Narrower covers risk skipping tests that
# would have killed mutations in the called subjects. Adapter-specific
# tests under test/multi_json/adapters/ use a tighter
# ``cover "MultiJSON::Adapters::<Name>*"`` because they have an
# unambiguous single-subject focus.

module TestHelpers
  include StubHelpers

  # Alias for backward compatibility with tests
  StrictAdapter = ::StrictAdapter

  module_function

  def adapter_available?(name)
    Gem.loaded_specs.key?(name.to_s)
  end

  def java?
    RUBY_ENGINE == "jruby"
  end

  def oj? = adapter_available?(:oj)
  # The backing gem is named ``yajl-ruby``, not ``yajl``.
  def yajl? = adapter_available?("yajl-ruby")
  def json? = adapter_available?(:json)
  def fast_jsonparser? = adapter_available?(:fast_jsonparser)
  def gson? = adapter_available?(:gson)
  def jrjackson? = adapter_available?(:jrjackson)

  def capture_stderr(&)
    original_stderr = $stderr
    $stderr = StringIO.new
    silence_warnings(&)
  ensure
    $stderr = original_stderr
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
    replacements = MultiJSON::AdapterSelector::REQUIREMENT_MAP.transform_values { |library| "foo/#{library}" }
    stub_constant(MultiJSON::AdapterSelector, :REQUIREMENT_MAP, replacements, &)
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

  def simulate_no_adapters(&)
    break_requirements { undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser, &) }
  end

  def get_exception(exception_class = StandardError)
    yield
    nil
  rescue exception_class => e
    e
  end

  def with_default_options
    adapter = MultiJSON.adapter
    adapter.load_options = adapter.dump_options = MultiJSON.load_options = MultiJSON.dump_options = nil
    yield
  ensure
    adapter.load_options = adapter.dump_options = MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def clear_default_adapter_warning
    return unless MultiJSON.instance_variable_defined?(:@default_adapter_warning_shown)

    MultiJSON.remove_instance_variable(:@default_adapter_warning_shown)
  end

  EXPECTED_DEFAULT_ADAPTER_PROBES = [
    [:JrJackson, "MultiJSON::Adapters::JrJackson"],
    ["JSON::Ext::Parser", "MultiJSON::Adapters::JsonGem"],
    [:FastJsonparser, "MultiJSON::Adapters::FastJsonparser"],
    [:Oj, "MultiJSON::Adapters::Oj"],
    [:Yajl, "MultiJSON::Adapters::Yajl"],
    [:Gson, "MultiJSON::Adapters::Gson"]
  ].freeze

  # Mirrors AdapterSelector#loaded_adapter: walks the probe list in
  # preference order and returns the first whose backing constant is
  # currently defined. Using ``defined?`` rather than gem-availability
  # checks keeps this in lockstep with the live constant state, which
  # other tests temporarily mutate.
  def expected_default_adapter
    return "MultiJSON::Adapters::JrJackson" if java? && Object.const_defined?(:JrJackson)

    EXPECTED_DEFAULT_ADAPTER_PROBES.each do |constant_path, adapter_class|
      return adapter_class if Object.const_defined?(constant_path)
    end
    "MultiJSON::Adapters::JsonGem"
  end

  def track_current_adapter_options(&)
    adapter = nil
    stub = ->(opts = {}) { adapter = opts[:adapter] if opts.is_a?(Hash) }
    with_stub(MultiJSON, :current_adapter, stub, call_original: true, &)
    adapter
  end
end

module Minitest
  class Test
    include TestHelpers
  end
end
