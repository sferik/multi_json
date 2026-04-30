# frozen_string_literal: true

require_relative "../../../test_helper"

class DeprecatedDumpAliasTest < Minitest::Test
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

  def test_dump_delegates_to_generate
    @registry.add(:dump)

    assert_equal '{"foo":"bar"}', MultiJSON.dump({foo: "bar"})
  end

  def test_dump_forwards_options
    @registry.add(:dump)
    MultiJSON.use :json_gem

    assert_includes MultiJSON.dump({foo: "bar"}, pretty: true), "\n"
  end

  def test_dump_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.dump({a: 1})
    restore_warn

    assert_includes msg, "MultiJSON.dump"
    assert_includes msg, "MultiJSON.generate"
  end

  def test_dump_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.dump({a: 1}) }
    restore_warn

    assert_equal 1, n
  end

  def test_dump_keyed_by_dump_symbol
    @registry.add(:dump)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.dump({a: 1})
    restore_warn

    assert_equal 0, n
  end

  def test_dump_default_options_is_empty_hash_not_nil
    @registry.add(:dump)
    captured_options = nil
    stub = ->(_object, options = {}) { captured_options = options }
    with_stub(MultiJSON, :generate, stub) { MultiJSON.dump({a: 1}) }

    refute_nil captured_options
    assert_empty captured_options
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
