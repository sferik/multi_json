# frozen_string_literal: true

require_relative "../../../test_helper"

class DeprecatedWithEngineAliasTest < Minitest::Test
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

  def test_with_engine_delegates_to_with_adapter
    skip unless defined?(::Oj)
    @registry.add(:with_engine)
    inside = nil
    MultiJSON.with_engine(:oj) { inside = MultiJSON.adapter }

    assert_equal MultiJSON::Adapters::Oj, inside
  end

  def test_with_engine_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJSON.with_engine(:json_gem) { nil }
    restore_warn

    assert_includes msg, "MultiJSON.with_engine"
  end

  def test_with_engine_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJSON.with_engine(:json_gem) { nil } }
    restore_warn

    assert_equal 1, n
  end

  def test_with_engine_keyed_by_with_engine_symbol
    @registry.add(:with_engine)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJSON.with_engine(:json_gem) { nil }
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
