# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for deprecated warning behavior
class DeprecatedWarningBehaviorTest < Minitest::Test
  cover "MultiJson*"

  def setup
    # Clear the per-process deprecation registry so each test starts fresh
    MultiJson.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).clear
  end

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

  def test_default_options_warns_only_once_per_process
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_count += 1 } }

    MultiJson.default_options
    MultiJson.default_options
    MultiJson.default_options

    assert_equal 1, warn_count
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

  def test_warn_deprecation_once_is_thread_safe
    warn_count = 0
    original_warn = Kernel.method(:warn)
    # The sleep gives concurrent threads a real chance of racing past the
    # include? check before either calls add, exposing an unsynchronized
    # warn_deprecation_once.
    racing_warn = ->(_msg) { sleep(0.01) && (warn_count += 1) }
    silence_warnings { Kernel.define_singleton_method(:warn, &racing_warn) }
    Array.new(10) { Thread.new { MultiJson.cached_options } }.each(&:join)

    assert_equal 1, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end
