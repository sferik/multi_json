require_relative "../../../test_helper"

class DeprecatedEncodeAliasTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @registry = MultiJson.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @original_adapter = MultiJson.adapter
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.adapter = @original_adapter
  end

  def test_encode_delegates_to_dump
    @registry.add(:encode)

    assert_equal '{"foo":"bar"}', MultiJson.encode({foo: "bar"})
  end

  def test_encode_forwards_options
    @registry.add(:encode)
    MultiJson.use :json_gem

    assert_includes MultiJson.encode({foo: "bar"}, pretty: true), "\n"
  end

  def test_encode_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJson.encode({a: 1})
    restore_warn

    assert_includes msg, "MultiJson.encode"
  end

  def test_encode_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJson.encode({a: 1}) }
    restore_warn

    assert_equal 1, n
  end

  def test_encode_keyed_by_encode_symbol
    @registry.add(:encode)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJson.encode({a: 1})
    restore_warn

    assert_equal 0, n
  end

  def test_encode_default_options_is_empty_hash_not_nil
    @registry.add(:encode)
    captured_options = nil
    stub = ->(_object, options = {}) { captured_options = options }
    with_stub(MultiJson, :dump, stub) { MultiJson.encode({a: 1}) }

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
