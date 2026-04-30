# frozen_string_literal: true

require_relative "../../../test_helper"

# Verifies the deprecated :symbolize_keys option translates to
# :symbolize_names with a one-time deprecation warning, covering
# the three option-layers (adapter, global, call-site) and the
# override semantics.
class DeprecatedSymbolizeKeysOptionTest < Minitest::Test
  cover "MultiJSON*"
  cover "MultiJSON::Adapter*"

  def setup
    @registry = MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @original_adapter = MultiJSON.adapter
    MultiJSON.use :json_gem
    MultiJSON.parse_options = nil
    MultiJSON::OptionsCache.reset
  end

  def teardown
    MultiJSON.parse_options = nil
    MultiJSON::OptionsCache.reset
    MultiJSON.adapter = @original_adapter
  end

  def test_symbolize_keys_at_call_site_still_symbolizes
    @registry.add(:symbolize_keys_option)

    result = MultiJSON.parse('{"a":1}', symbolize_keys: true)

    assert_equal({a: 1}, result)
  end

  def test_symbolize_keys_false_at_call_site_leaves_string_keys
    @registry.add(:symbolize_keys_option)

    result = MultiJSON.parse('{"a":1}', symbolize_keys: false)

    assert_equal({"a" => 1}, result)
  end

  def test_symbolize_keys_emits_deprecation_warning
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.parse('{"a":1}', symbolize_keys: true)
    restore_warn

    assert_includes msg, ":symbolize_keys"
    assert_includes msg, ":symbolize_names"
    assert_includes msg, "deprecated"
  end

  def test_symbolize_keys_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { |i| MultiJSON.parse(%({"k":#{i}}), symbolize_keys: true) }
    restore_warn

    assert_equal 1, n
  end

  def test_symbolize_keys_keyed_by_symbolize_keys_option_symbol
    @registry.add(:symbolize_keys_option)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.parse('{"a":1}', symbolize_keys: true)
    restore_warn

    assert_equal 0, n
  end

  def test_symbolize_keys_in_global_parse_options_still_symbolizes
    @registry.add(:symbolize_keys_option)
    MultiJSON.parse_options = {symbolize_keys: true}
    MultiJSON::OptionsCache.reset

    result = MultiJSON.parse('{"a":1}')

    assert_equal({a: 1}, result)
  end

  def test_symbolize_names_takes_precedence_when_both_present
    @registry.add(:symbolize_keys_option)

    result = MultiJSON.parse('{"a":1}', symbolize_keys: true, symbolize_names: false)

    assert_equal({"a" => 1}, result)
  end

  def test_symbolize_names_at_call_site_does_not_warn
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.parse('{"a":1}', symbolize_names: true)
    restore_warn

    assert_equal 0, n
  end

  def test_call_site_symbolize_keys_overrides_global_symbolize_names
    @registry.add(:symbolize_keys_option)
    MultiJSON.parse_options = {symbolize_names: false}
    MultiJSON::OptionsCache.reset

    result = MultiJSON.parse('{"a":1}', symbolize_keys: true)

    assert_equal({a: 1}, result)
  end

  private

  def capture_warn(&block)
    @original_warn = Kernel.method(:warn)
    silence_warnings { Kernel.define_singleton_method(:warn, &block) }
  end

  def restore_warn
    silence_warnings { Kernel.define_singleton_method(:warn, @original_warn) }
  end
end
