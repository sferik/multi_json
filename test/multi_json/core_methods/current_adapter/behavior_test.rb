require_relative "../../../test_helper"

# Tests for current_adapter method behavior
class CurrentAdapterBehaviorTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_current_adapter_returns_value_not_nil
    MultiJson.use :json_gem

    result = MultiJson.current_adapter

    refute_nil result
    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_current_adapter_body_executes
    MultiJson.use :json_gem

    result = MultiJson.current_adapter

    refute_nil result
  end

  def test_current_adapter_uses_passed_options
    MultiJson.use :json_gem

    result = MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_accesses_options_bracket_adapter
    MultiJson.use :json_gem

    result = MultiJson.current_adapter({adapter: :ok_json})

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_uses_assignment_value
    MultiJson.use :json_gem

    result = MultiJson.current_adapter(adapter: :ok_json)

    refute_equal MultiJson.adapter, result unless MultiJson.adapter == MultiJson::Adapters::OkJson

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_does_not_raise
    result = MultiJson.current_adapter

    refute_nil result
  end

  def test_current_adapter_instance_method_accepts_no_arguments
    MultiJson.use :json_gem
    bound = MultiJson.instance_method(:current_adapter).bind(MultiJson)

    assert_equal MultiJson::Adapters::JsonGem, bound.call
  end

  def test_current_adapter_instance_method_accepts_nil_options
    MultiJson.use :json_gem
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }
    object.send(:use, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, object.send(:current_adapter, nil)
  end

  def test_current_adapter_instance_method_uses_adapter_option
    MultiJson.use :json_gem
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }

    result = object.send(:current_adapter, adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_uses_hash_literal_default_argument
    skip "RubyVM::InstructionSequence not available" unless defined?(RubyVM::InstructionSequence)

    iseq = RubyVM::InstructionSequence.of(MultiJson.instance_method(:current_adapter))
    first_instruction = iseq.disasm.lines.find { |line| line.strip.start_with?("0000") }

    assert_includes first_instruction, "newhash"
    refute_includes first_instruction, "putnil"
  end

  def test_current_adapter_definition_includes_default_hash_argument
    file, = MultiJson.instance_method(:current_adapter).source_location
    source = File.read(file)

    assert_includes source, "def current_adapter(options = {})"
  end
end
