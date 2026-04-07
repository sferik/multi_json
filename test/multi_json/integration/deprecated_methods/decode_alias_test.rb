require_relative "../../../test_helper"

class DeprecatedDecodeAliasTest < Minitest::Test
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

  def test_decode_delegates_to_load
    @registry.add(:decode)

    assert_equal({"foo" => "bar"}, MultiJson.decode('{"foo":"bar"}'))
  end

  def test_decode_forwards_options
    @registry.add(:decode)

    assert_equal({foo: "bar"}, MultiJson.decode('{"foo":"bar"}', symbolize_keys: true))
  end

  def test_decode_warns_with_method_name
    msg = nil
    capture_warn { |m| msg ||= m }
    MultiJson.decode('{"a":1}')
    restore_warn

    assert_includes msg, "MultiJson.decode"
  end

  def test_decode_warns_only_once
    n = 0
    capture_warn { |_m| n += 1 }
    3.times { MultiJson.decode('{"a":1}') }
    restore_warn

    assert_equal 1, n
  end

  def test_decode_keyed_by_decode_symbol
    @registry.add(:decode)
    n = 0
    capture_warn { |_m| n += 1 }
    MultiJson.decode('{"a":1}')
    restore_warn

    assert_equal 0, n
  end

  def test_decode_default_options_is_empty_hash_not_nil
    @registry.add(:decode)
    captured_options = nil
    stub = ->(_string, options = {}) { captured_options = options }
    with_stub(MultiJson, :load, stub) { MultiJson.decode('{"a":1}') }

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
