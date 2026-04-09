# frozen_string_literal: true

require_relative "../test_helper"

# Direct unit tests for the synchronize_* wrappers in
# `MultiJson::Concurrency`. The wrappers are also exercised indirectly
# through their upstream callers — `MultiJson.use`, `Options#default_*`,
# `AdapterSelector#default_adapter`, etc. — but `synchronize_dump_delegate`
# is only invoked from the `fast_jsonparser` adapter, which isn't loaded
# on JRuby. Without these direct tests, JRuby's coverage drops below the
# 100% threshold the instant the wrapper is introduced.
class ConcurrencyTest < Minitest::Test
  cover "MultiJson::Concurrency*"

  WRAPPERS = %i[
    synchronize_deprecation_warnings
    synchronize_adapter
    synchronize_default_adapter
    synchronize_default_options
    synchronize_dump_delegate
  ].freeze

  WRAPPERS.each do |wrapper|
    define_method(:"test_#{wrapper}_yields") do
      yielded = false
      MultiJson::Concurrency.public_send(wrapper) { yielded = true }

      assert yielded
    end

    define_method(:"test_#{wrapper}_returns_block_value") do
      result = MultiJson::Concurrency.public_send(wrapper) { :sentinel }

      assert_equal :sentinel, result
    end
  end
end
