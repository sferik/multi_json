require_relative "../../../test_helper"
require_relative "dump_test"

class InstanceMethodCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    @object.send(:use, :json_gem)
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_current_adapter_returns_adapter
    result = @object.send(:current_adapter)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_instance_current_adapter_with_adapter_option
    result = @object.send(:current_adapter, adapter: :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_instance_current_adapter_handles_nil_options
    result = @object.send(:current_adapter, nil)

    refute_nil result
  end

  private

  def create_multi_json_object
    InstanceMethodDumpTest::MultiJsonTestObject.new
  end
end
