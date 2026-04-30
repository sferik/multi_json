# frozen_string_literal: true

require_relative "../../../test_helper"

class DeprecatedDumpOptionsAliasTest < Minitest::Test
  cover "MultiJSON*"
  cover "MultiJSON::Options*"

  def setup
    @registry = MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @original_adapter = MultiJSON.adapter
    MultiJSON.use :json_gem
    MultiJSON.generate_options = nil
  end

  def teardown
    MultiJSON.generate_options = nil
    MultiJSON.adapter = @original_adapter
  end

  def test_dump_options_setter_delegates_to_generate_options
    @registry.add(:dump_options=)
    MultiJSON.dump_options = {pretty: true}

    assert_equal({pretty: true}, MultiJSON.generate_options)
  end

  def test_dump_options_getter_delegates_to_generate_options
    @registry.add(:dump_options=)
    @registry.add(:dump_options)
    MultiJSON.dump_options = {pretty: true}

    assert_equal({pretty: true}, MultiJSON.dump_options)
  end

  def test_dump_options_setter_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.dump_options = {pretty: true}
    restore_warn

    assert_includes msg, "MultiJSON.dump_options"
    assert_includes msg, "MultiJSON.generate_options"
  end

  def test_dump_options_getter_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.dump_options
    restore_warn

    assert_includes msg, "MultiJSON.dump_options"
    assert_includes msg, "MultiJSON.generate_options"
  end

  def test_dump_options_setter_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.dump_options = {pretty: true} }
    restore_warn

    assert_equal 1, n
  end

  def test_dump_options_getter_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.dump_options }
    restore_warn

    assert_equal 1, n
  end

  def test_dump_options_setter_stores_in_generate_options_ivar
    @registry.add(:dump_options=)
    MultiJSON.dump_options = {pretty: true}

    assert_equal({pretty: true}, MultiJSON.instance_variable_get(:@generate_options))
  end

  def test_dump_options_setter_keyed_by_dump_options_setter_symbol
    @registry.add(:dump_options=)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.dump_options = {pretty: true}
    restore_warn

    assert_equal 0, n
  end

  def test_dump_options_getter_keyed_by_dump_options_symbol
    @registry.add(:dump_options)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.dump_options
    restore_warn

    assert_equal 0, n
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
