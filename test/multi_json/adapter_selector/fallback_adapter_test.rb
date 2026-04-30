# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/adapter_selector"

# Tests the private fallback_adapter helper, which is called only when
# every other JSON library fails to load. Now that json is a Ruby
# default gem, this path never fires in production — but it's still
# exercised by simulate_no_adapters and must remain correct.
class FallbackAdapterTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_fallback_adapter_returns_json_gem
    clear_default_adapter_warning
    result = capture_stderr { MultiJSON.send(:fallback_adapter) }

    assert_equal :json_gem, result
  end

  def test_fallback_adapter_shows_warning
    clear_default_adapter_warning
    warned = false

    with_stub(Kernel, :warn, ->(_, **) { warned = true }) do
      MultiJSON.send(:fallback_adapter)
    end

    assert warned
  end

  def test_fallback_adapter_warns_only_once
    clear_default_adapter_warning
    warn_count = 0

    with_stub(Kernel, :warn, ->(_, **) { warn_count += 1 }) do
      MultiJSON.send(:fallback_adapter)
      MultiJSON.send(:fallback_adapter)
    end

    assert_equal 1, warn_count
  end

  def test_fallback_adapter_sets_warning_shown_flag
    clear_default_adapter_warning
    capture_stderr { MultiJSON.send(:fallback_adapter) }

    assert MultiJSON.instance_variable_get(:@default_adapter_warning_shown)
  end

  def test_fallback_adapter_warning_mentions_multijson
    clear_default_adapter_warning
    captured = nil

    with_stub(Kernel, :warn, ->(msg, **) { captured = msg }) do
      MultiJSON.send(:fallback_adapter)
    end

    refute_nil captured
    assert_includes captured, "MultiJSON"
  end
end
