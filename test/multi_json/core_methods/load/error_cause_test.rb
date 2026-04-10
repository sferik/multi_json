# frozen_string_literal: true

require_relative "../../../test_helper"

class LoadErrorCauseTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_error_cause_is_set
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad}") }

    # The cause should be set, not nil
    refute_nil error.cause
    assert_kind_of Exception, error.cause
  end

  def test_load_error_cause_uses_cause_keyword
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad}") }

    # Verify cause is actually set via the cause: keyword
    refute_nil error.cause, "cause should be set via cause: keyword, not cause__mutant__:"
  end

  def test_load_error_sets_cause
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{invalid}") }

    refute_nil error.cause, "cause must be set via cause: keyword argument"
  end

  def test_load_raises_adapter_error_when_adapter_lacks_parse_error
    custom = adapter_without_parse_error
    error = assert_raises(MultiJson::AdapterError) { MultiJson.load('{"a":1}', adapter: custom) }

    assert_match(/ParseError constant/, error.message)
    assert_includes error.message, custom.to_s
  end

  def test_load_raises_adapter_error_when_adapter_lacks_load
    error = assert_raises(MultiJson::AdapterError) do
      MultiJson.load('{"a":1}', adapter: adapter_without_load)
    end

    assert_match(/must respond to \.load/, error.message)
  end

  def test_load_raises_adapter_error_when_adapter_lacks_dump_before_parsing
    error = assert_raises(MultiJson::AdapterError) do
      MultiJson.load('{"a":1}', adapter: adapter_without_dump)
    end

    assert_match(/must respond to \.dump/, error.message)
  end

  def test_load_ignores_top_level_parse_error_inherited_from_object
    Object.const_set(:ParseError, Class.new(StandardError))
    custom = adapter_without_parse_error
    error = assert_raises(MultiJson::AdapterError) { MultiJson.load('{"a":1}', adapter: custom) }

    assert_match(/ParseError constant/, error.message)
  ensure
    Object.send(:remove_const, :ParseError) if Object.const_defined?(:ParseError, false)
  end

  # Verifies the lookup is performed via ``const_get(:ParseError, false)``
  # rather than the ``::`` operator. The two are equivalent on MRI but
  # diverge on TruffleRuby, whose ``::`` operator walks the ancestor
  # chain and would otherwise pick up a top-level ``::ParseError``
  # constant. The test installs a tracking ``const_get`` override on a
  # bare adapter class and asserts both that ``const_get`` is called
  # *and* that the second argument is ``false`` — a mutation switching
  # the call to ``adapter_class::ParseError`` skips the override and
  # leaves the tracker unset, killing the mutation on MRI.
  def test_parse_error_class_for_uses_const_get_with_inherit_false
    custom = adapter_with_parse_error
    inherit_argument = :not_called
    custom.define_singleton_method(:const_get) do |name, inherit = true|
      inherit_argument = inherit if name == :ParseError
      super(name, inherit)
    end

    MultiJson.parse_error_class_for(custom)

    refute inherit_argument
  end

  def test_parse_error_class_for_returns_cached_value_when_present
    custom = adapter_with_parse_error
    sentinel = Class.new(StandardError)
    custom.instance_variable_set(:@_multi_json_parse_error, sentinel)

    assert_same sentinel, MultiJson.parse_error_class_for(custom)
  end

  def test_parse_error_class_for_skips_const_get_on_cache_hit
    custom = adapter_with_parse_error
    custom.instance_variable_set(:@_multi_json_parse_error, custom::ParseError)
    const_get_called = false
    custom.define_singleton_method(:const_get) do |*args|
      const_get_called = true
      super(*args)
    end

    MultiJson.parse_error_class_for(custom)

    refute const_get_called
  end

  def test_parse_error_class_for_caches_resolved_class_on_adapter
    custom = adapter_with_parse_error

    resolved = MultiJson.parse_error_class_for(custom)

    assert_same resolved, custom.instance_variable_get(:@_multi_json_parse_error)
    assert_same custom::ParseError, resolved
  end

  private

  def adapter_without_parse_error
    Class.new do
      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = nil
    end
  end

  def adapter_with_parse_error
    Class.new do
      const_set(:ParseError, Class.new(StandardError))
      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = nil
    end
  end

  def adapter_without_load
    Class.new do
      const_set(:ParseError, Class.new(StandardError))
      def self.dump(_object, _options) = nil
    end
  end

  def adapter_without_dump
    Class.new do
      const_set(:ParseError, Class.new(StandardError))
      def self.load(_string, _options) = nil
    end
  end
end
