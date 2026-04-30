# frozen_string_literal: true

require_relative "../../../test_helper"

class ParseErrorClassTest < Minitest::Test
  cover "MultiJSON*"

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

    MultiJSON.parse_error_class_for(custom)

    refute inherit_argument
  end

  def test_parse_error_class_for_returns_cached_value_when_present
    custom = adapter_with_parse_error
    sentinel = Class.new(StandardError)
    custom.instance_variable_set(:@_multi_json_parse_error, sentinel)

    assert_same sentinel, MultiJSON.parse_error_class_for(custom)
  end

  def test_parse_error_class_for_skips_const_get_on_cache_hit
    custom = adapter_with_parse_error
    custom.instance_variable_set(:@_multi_json_parse_error, custom::ParseError)
    const_get_called = false
    custom.define_singleton_method(:const_get) do |*args|
      const_get_called = true
      super(*args)
    end

    MultiJSON.parse_error_class_for(custom)

    refute const_get_called
  end

  def test_parse_error_class_for_caches_resolved_class_on_adapter
    custom = adapter_with_parse_error

    resolved = MultiJSON.parse_error_class_for(custom)

    assert_same resolved, custom.instance_variable_get(:@_multi_json_parse_error)
    assert_same custom::ParseError, resolved
  end

  private

  def adapter_with_parse_error
    Class.new do
      const_set(:ParseError, Class.new(StandardError))
      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = nil
    end
  end
end
