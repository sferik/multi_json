require_relative "../../test_helper"
require "multi_json/adapter_selector"

class FallbackAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_fallback_adapter_returns_ok_json
    result = MultiJson.send(:fallback_adapter)

    assert_equal :ok_json, result
  end

  def test_fallback_adapter_shows_warning
    clear_default_adapter_warning
    warned = false

    with_stub(Kernel, :warn, ->(_) { warned = true }) do
      MultiJson.send(:fallback_adapter)
    end

    assert warned
  end

  def test_fallback_adapter_warns_only_once
    clear_default_adapter_warning
    warn_count = 0

    with_stub(Kernel, :warn, ->(_) { warn_count += 1 }) do
      MultiJson.send(:fallback_adapter)
      MultiJson.send(:fallback_adapter)
    end

    assert_equal 1, warn_count
  end

  def test_fallback_adapter_sets_warning_shown_flag
    clear_default_adapter_warning

    capture_stderr { MultiJson.send(:fallback_adapter) }

    assert MultiJson.instance_variable_get(:@default_adapter_warning_shown)
  end
end

class FallbackAdapterWarningBehaviorTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_fallback_adapter_returns_ok_json
    clear_default_adapter_warning

    result = capture_stderr { MultiJson.send(:fallback_adapter) }

    assert_equal :ok_json, result
  end

  def test_fallback_adapter_calls_kernel_warn
    clear_default_adapter_warning
    warned = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_| warned = true } }

    MultiJson.send(:fallback_adapter)

    assert warned
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_fallback_adapter_sets_warning_shown_flag
    clear_default_adapter_warning

    capture_stderr { MultiJson.send(:fallback_adapter) }

    assert MultiJson.instance_variable_get(:@default_adapter_warning_shown)
  end

  def test_fallback_adapter_only_warns_once
    clear_default_adapter_warning
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_| warn_count += 1 } }

    MultiJson.send(:fallback_adapter)
    MultiJson.send(:fallback_adapter)

    assert_equal 1, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_fallback_adapter_warning_message_not_nil
    clear_default_adapter_warning
    warning_received = nil
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| warning_received = msg } }

    MultiJson.send(:fallback_adapter)

    refute_nil warning_received, "Warning message should not be nil"
    assert_includes warning_received, "MultiJson"
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end
