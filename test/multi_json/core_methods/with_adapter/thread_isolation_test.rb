require_relative "../../../test_helper"

# Verifies that with_adapter overrides are isolated per thread (and per
# fiber), so concurrent blocks do not clobber each other's "previous adapter"
# state. Before the fiber-local change this would race on the module-level
# @adapter ivar.
class WithAdapterThreadIsolationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_with_adapter_isolated_across_threads
    process_default = MultiJson.adapter
    observed = run_overlapping_threads(ok_json: MultiJson::Adapters::OkJson,
      json_gem: MultiJson::Adapters::JsonGem)

    assert_equal MultiJson::Adapters::OkJson, observed[:ok_json]
    assert_equal MultiJson::Adapters::JsonGem, observed[:json_gem]
    assert_equal process_default, MultiJson.adapter
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
    MultiJson.with_adapter(target) do
      sleep 0.05 # encourage overlap
      mutex.synchronize { observed[target] = MultiJson.adapter }
    end
  end
end
