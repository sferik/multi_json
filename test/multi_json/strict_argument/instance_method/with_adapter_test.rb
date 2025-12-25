require_relative "../../../test_helper"
require_relative "dump_test"

class InstanceMethodWithAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    @object.send(:use, :json_gem)
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_with_adapter_changes_adapter
    inner_adapter = nil

    @object.send(:with_adapter, :ok_json) do
      inner_adapter = @object.send(:adapter)
    end

    assert_equal MultiJson::Adapters::OkJson, inner_adapter
  end

  def test_instance_with_adapter_restores_adapter
    @object.send(:use, :json_gem)

    @object.send(:with_adapter, :ok_json) { nil }

    assert_equal MultiJson::Adapters::JsonGem, @object.send(:adapter)
  end

  def test_instance_with_adapter_returns_block_value
    result = @object.send(:with_adapter, :ok_json) { "result" }

    assert_equal "result", result
  end

  private

  def create_multi_json_object
    InstanceMethodDumpTest::MultiJsonTestObject.new
  end
end
