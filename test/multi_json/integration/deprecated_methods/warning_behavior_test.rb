require_relative "../../../test_helper"

# Tests for deprecated warning behavior
class DeprecatedWarningBehaviorTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.default_options = {}

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.default_options

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_cached_options_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.cached_options

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_reset_cached_options_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.reset_cached_options!

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_cached_options_warning_includes_method_name
    warning_message = nil
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| warning_message = msg } }

    MultiJson.cached_options

    assert_includes warning_message, "cached_options"
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_reset_cached_options_warning_includes_method_name
    warning_message = nil
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| warning_message = msg } }

    MultiJson.reset_cached_options!

    assert_includes warning_message, "reset_cached_options!"
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end
