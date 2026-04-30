# frozen_string_literal: true

require_relative "../../../test_helper"

# Verifies the backward-compat `MultiJson` (CamelCase) constant
# forwards method calls to `MultiJSON` with a one-time warning.
class DeprecatedConstantAliasMethodTest < Minitest::Test
  cover "MultiJson*"
  cover "MultiJSON*"

  def setup
    @registry = MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @original_adapter = MultiJSON.adapter
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.adapter = @original_adapter
  end

  def test_method_call_delegates_to_multijson
    @registry.add(:multi_json_constant)

    assert_equal({"foo" => "bar"}, MultiJson.parse('{"foo":"bar"}'))
  end

  def test_method_call_forwards_positional_and_keyword_arguments
    @registry.add(:multi_json_constant)

    assert_equal({foo: "bar"}, MultiJson.parse('{"foo":"bar"}', symbolize_names: true))
  end

  def test_method_call_forwards_block
    @registry.add(:multi_json_constant)
    result = MultiJson.with_adapter(:json_gem) { MultiJSON.adapter }

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_method_call_emits_deprecation_warning
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJson.parse('{"a":1}')
    restore_warn

    assert_includes msg, "MultiJson"
    assert_includes msg, "MultiJSON"
    assert_includes msg, "deprecated"
  end

  def test_method_call_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJson.parse('{"a":1}') }
    restore_warn

    assert_equal 1, n
  end

  def test_method_call_keyed_by_multi_json_constant_symbol
    @registry.add(:multi_json_constant)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJson.parse('{"a":1}')
    restore_warn

    assert_equal 0, n
  end

  def test_method_missing_raises_for_unknown_method
    @registry.add(:multi_json_constant)

    assert_raises(NoMethodError) { MultiJson.definitely_not_a_real_method }
  end

  def test_respond_to_recognizes_known_methods
    assert_respond_to MultiJson, :parse
  end

  def test_respond_to_rejects_unknown_methods
    refute_respond_to MultiJson, :definitely_not_a_real_method
  end

  private

  def capture_warn(&block)
    @original_warn = Kernel.method(:warn)
    silence_warnings { Kernel.define_singleton_method(:warn) { |msg, **| block.call(msg) } }
  end

  def restore_warn
    silence_warnings { Kernel.define_singleton_method(:warn, @original_warn) }
  end
end

# Verifies the backward-compat `MultiJson` constant resolves nested
# constants to their `MultiJSON` counterparts via `const_missing`.
class DeprecatedConstantAliasConstTest < Minitest::Test
  cover "MultiJson*"
  cover "MultiJSON*"

  def setup
    @registry = MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
  end

  def test_const_missing_resolves_to_multijson_constant
    @registry.add(:multi_json_constant)

    assert_same MultiJSON::ParseError, MultiJson::ParseError
  end

  def test_const_missing_resolves_nested_adapter_classes
    @registry.add(:multi_json_constant)

    assert_same MultiJSON::Adapters::JsonGem, MultiJson::Adapters::JsonGem
  end

  def test_const_missing_emits_deprecation_warning
    msg = nil
    capture_warn { |m| msg ||= m }
    _resolved = MultiJson::ParseError
    restore_warn

    assert_includes msg, "MultiJson"
    assert_includes msg, "MultiJSON"
    assert_includes msg, "deprecated"
  end

  def test_const_missing_keyed_by_multi_json_constant_symbol
    @registry.add(:multi_json_constant)
    n = 0
    capture_warn { |_m| n += 1 }
    _resolved = MultiJson::ParseError
    restore_warn

    assert_equal 0, n
  end

  def test_rescue_clause_works_through_const_missing
    @registry.add(:multi_json_constant)
    caught = nil

    begin
      raise MultiJSON::ParseError, "boom"
    rescue MultiJson::ParseError => e
      caught = e
    end

    refute_nil caught
    assert_kind_of MultiJSON::ParseError, caught
  end

  private

  def capture_warn(&block)
    @original_warn = Kernel.method(:warn)
    silence_warnings { Kernel.define_singleton_method(:warn) { |msg, **| block.call(msg) } }
  end

  def restore_warn
    silence_warnings { Kernel.define_singleton_method(:warn, @original_warn) }
  end
end
