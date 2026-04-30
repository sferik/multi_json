# frozen_string_literal: true

require_relative "../../../test_helper"

class DeprecatedLoadOptionsAliasTest < Minitest::Test
  cover "MultiJSON*"
  cover "MultiJSON::Options*"

  def setup
    @registry = MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @original_adapter = MultiJSON.adapter
    MultiJSON.use :json_gem
    MultiJSON.parse_options = nil
  end

  def teardown
    MultiJSON.parse_options = nil
    MultiJSON.adapter = @original_adapter
  end

  def test_load_options_setter_delegates_to_parse_options
    @registry.add(:load_options=)
    MultiJSON.load_options = {symbolize_names: true}

    assert_equal({symbolize_names: true}, MultiJSON.parse_options)
  end

  def test_load_options_getter_delegates_to_parse_options
    @registry.add(:load_options=)
    @registry.add(:load_options)
    MultiJSON.load_options = {symbolize_names: true}

    assert_equal({symbolize_names: true}, MultiJSON.load_options)
  end

  def test_load_options_setter_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.load_options = {symbolize_names: true}
    restore_warn

    assert_includes msg, "MultiJSON.load_options"
    assert_includes msg, "MultiJSON.parse_options"
  end

  def test_load_options_getter_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.load_options
    restore_warn

    assert_includes msg, "MultiJSON.load_options"
    assert_includes msg, "MultiJSON.parse_options"
  end

  def test_load_options_setter_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.load_options = {symbolize_names: true} }
    restore_warn

    assert_equal 1, n
  end

  def test_load_options_getter_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.load_options }
    restore_warn

    assert_equal 1, n
  end

  def test_load_options_setter_stores_in_parse_options_ivar
    @registry.add(:load_options=)
    MultiJSON.load_options = {symbolize_names: true}

    assert_equal({symbolize_names: true}, MultiJSON.instance_variable_get(:@parse_options))
  end

  def test_load_options_setter_keyed_by_load_options_setter_symbol
    @registry.add(:load_options=)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.load_options = {symbolize_names: true}
    restore_warn

    assert_equal 0, n
  end

  def test_load_options_getter_keyed_by_load_options_symbol
    @registry.add(:load_options)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.load_options
    restore_warn

    assert_equal 0, n
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
