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

  private

  def adapter_without_parse_error
    Class.new do
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
