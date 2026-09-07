# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for deprecated warning behavior
class DeprecationWarningFlagTest < Minitest::Test
  cover "MultiJSON*"

  # Ruby 3.0+ hides ``category: :deprecated`` warnings natively. On 2.7
  # the library checks ``Warning[:deprecated]`` itself, so this only
  # exercises that path.
  def test_warn_deprecation_once_is_silent_when_deprecated_warnings_are_off
    skip "Ruby 3.0+ gates category: :deprecated warnings natively" if RUBY_VERSION >= "3.0"
    warned = false
    with_deprecated_warnings(false) do
      with_stub(Kernel, :warn, ->(*) { warned = true }) { MultiJSON.warn_deprecation_once(:flag_probe, "probe message") }
    end

    refute warned
  end

  private

  def with_deprecated_warnings(enabled)
    original = Warning[:deprecated]
    Warning[:deprecated] = enabled
    yield
  ensure
    Warning[:deprecated] = original
  end
end
