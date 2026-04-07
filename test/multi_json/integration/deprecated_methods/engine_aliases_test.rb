require_relative "../../../test_helper"

# Tests for the engine, engine=, and default_engine deprecated aliases.
class DeprecatedEngineAliasesTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @registry = MultiJson.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @original_adapter = MultiJson.adapter
    MultiJson.use :ok_json
  end

  def teardown
    MultiJson.adapter = @original_adapter
  end

  def test_default_engine_delegates_to_default_adapter
    @registry.add(:default_engine)

    assert_equal MultiJson.default_adapter, MultiJson.default_engine
  end

  def test_default_engine_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJson.default_engine
    restore_warn

    assert_includes msg, "MultiJson.default_engine"
  end

  def test_default_engine_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJson.default_engine }
    restore_warn

    assert_equal 1, n
  end

  def test_default_engine_keyed_by_default_engine_symbol
    @registry.add(:default_engine)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJson.default_engine
    restore_warn

    assert_equal 0, n
  end

  def test_engine_delegates_to_adapter
    @registry.add(:engine)

    assert_equal MultiJson.adapter, MultiJson.engine
  end

  def test_engine_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJson.engine
    restore_warn

    assert_includes msg, "MultiJson.engine"
  end

  def test_engine_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJson.engine }
    restore_warn

    assert_equal 1, n
  end

  def test_engine_keyed_by_engine_symbol
    @registry.add(:engine)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJson.engine
    restore_warn

    assert_equal 0, n
  end

  def test_engine_setter_delegates_to_adapter_setter
    @registry.add(:engine=)
    MultiJson.engine = :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_engine_setter_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJson.engine = :json_gem
    restore_warn

    assert_includes msg, "MultiJson.engine="
  end

  def test_engine_setter_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJson.engine = :json_gem }
    restore_warn

    assert_equal 1, n
  end

  def test_engine_setter_keyed_by_engine_setter_symbol
    @registry.add(:engine=)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJson.engine = :json_gem
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
