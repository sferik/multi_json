# frozen_string_literal: true

require_relative "../../../test_helper"
require_relative "dump_test"

class InstanceMethodUseTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_use_sets_adapter
    @object.send(:use, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, @object.send(:adapter)
  end

  def test_instance_use_returns_adapter
    result = @object.send(:use, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_instance_use_resets_options_cache
    key = :"instance_use_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached_value" }

    @object.send(:use, :json_gem)

    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil), "Cache should be cleared after use"
  end

  def test_instance_use_calls_reset_on_options_cache
    key = :"instance_reset_test_#{object_id}"
    MultiJson::OptionsCache.load.fetch(key) { "cached" }

    @object.send(:use, :json_gem)

    assert_nil MultiJson::OptionsCache.load.fetch(key, nil)
  end

  private

  def create_multi_json_object
    InstanceMethodDumpTest::MultiJsonTestObject.new
  end
end
