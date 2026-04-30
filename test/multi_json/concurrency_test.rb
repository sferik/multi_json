# frozen_string_literal: true

require_relative "../test_helper"

# Direct unit tests for `MultiJSON::Concurrency.synchronize`. The
# wrapper is also exercised indirectly through its upstream callers
# — `MultiJSON.use`, `Options#default_*`, `AdapterSelector#default_*`
# — but the `:dump_delegate` mutex is only invoked from the
# `fast_jsonparser` adapter, which isn't loaded on JRuby. Without
# these direct tests, JRuby's coverage drops below the 100% threshold
# the instant the wrapper is introduced.
class ConcurrencyTest < Minitest::Test
  cover "MultiJSON::Concurrency*"

  MUTEX_NAMES = %i[
    adapter
    default_adapter
    default_options
    generate_delegate
  ].freeze

  MUTEX_NAMES.each do |name|
    define_method(:"test_synchronize_#{name}_yields") do
      yielded = false
      MultiJSON::Concurrency.synchronize(name) { yielded = true }

      assert yielded
    end

    define_method(:"test_synchronize_#{name}_returns_block_value") do
      result = MultiJSON::Concurrency.synchronize(name) { :sentinel }

      assert_equal :sentinel, result
    end
  end

  def test_synchronize_raises_on_unknown_name
    assert_raises(KeyError) do
      MultiJSON::Concurrency.synchronize(:nonexistent) { nil }
    end
  end
end
