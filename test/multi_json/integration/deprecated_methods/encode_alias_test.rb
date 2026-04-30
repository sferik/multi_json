# frozen_string_literal: true

require_relative "../../../test_helper"

class DeprecatedEncodeAliasTest < Minitest::Test
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

  def test_encode_delegates_to_dump
    @registry.add(:encode)

    assert_equal '{"foo":"bar"}', MultiJSON.encode({foo: "bar"})
  end

  def test_encode_forwards_options
    @registry.add(:encode)
    MultiJSON.use :json_gem

    assert_includes MultiJSON.encode({foo: "bar"}, pretty: true), "\n"
  end

  def test_encode_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.encode({a: 1})
    restore_warn

    assert_includes msg, "MultiJSON.encode"
  end

  def test_encode_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.encode({a: 1}) }
    restore_warn

    assert_equal 1, n
  end

  def test_encode_keyed_by_encode_symbol
    @registry.add(:encode)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.encode({a: 1})
    restore_warn

    assert_equal 0, n
  end

  def test_encode_default_options_is_empty_hash_not_nil
    @registry.add(:encode)
    captured_options = nil
    stub = ->(_object, options = {}) { captured_options = options }
    with_stub(MultiJSON, :generate, stub) { MultiJSON.encode({a: 1}) }

    refute_nil captured_options
    assert_empty captured_options
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
