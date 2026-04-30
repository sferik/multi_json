# frozen_string_literal: true

require_relative "../../../test_helper"

# Verifies that with_adapter overrides are isolated per thread (and per
# fiber), so concurrent blocks do not clobber each other's "previous adapter"
# state. Before the fiber-local change this would race on the module-level
# @adapter ivar.
class WithAdapterThreadIsolationTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_with_adapter_isolated_across_threads
    skip unless defined?(::Oj)
    process_default = MultiJSON.adapter
    observed = run_overlapping_threads(json_gem: MultiJSON::Adapters::JsonGem,
      oj: MultiJSON::Adapters::Oj)

    assert_equal MultiJSON::Adapters::JsonGem, observed[:json_gem]
    assert_equal MultiJSON::Adapters::Oj, observed[:oj]
    assert_equal process_default, MultiJSON.adapter
  end

  private

  def run_overlapping_threads(targets)
    observed = {}
    mutex = Mutex.new
    threads = targets.each_key.map do |target|
      Thread.new { observe_in_block(target, mutex, observed) }
    end
    threads.each(&:join)
    observed
  end

  def observe_in_block(target, mutex, observed)
    MultiJSON.with_adapter(target) do
      sleep 0.05 # encourage overlap
      mutex.synchronize { observed[target] = MultiJSON.adapter }
    end
  end
end
