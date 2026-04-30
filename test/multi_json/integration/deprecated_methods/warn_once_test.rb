# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests that deprecation warnings honor the per-process registry: when a key
# is already marked as shown, the deprecated method must not warn again.
# These cases verify the symbol-to-key mapping for each deprecated method,
# pinning each method to its specific registry key.
class DeprecatedMethodsWarnOnceTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).clear
  end

  def test_default_options_getter_does_not_warn_when_already_marked
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).add(:default_options)
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg, **| warn_count += 1 } }

    MultiJSON.default_options

    assert_equal 0, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_default_options_setter_does_not_warn_when_already_marked
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).add(:default_options=)
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg, **| warn_count += 1 } }

    MultiJSON.default_options = {}

    assert_equal 0, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
    MultiJSON.parse_options = MultiJSON.generate_options = nil
  end

  def test_cached_options_does_not_warn_when_already_marked
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).add(:cached_options)
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg, **| warn_count += 1 } }

    MultiJSON.cached_options

    assert_equal 0, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_reset_cached_options_does_not_warn_when_already_marked
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).add(:reset_cached_options!)
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg, **| warn_count += 1 } }

    MultiJSON.reset_cached_options!

    assert_equal 0, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end
