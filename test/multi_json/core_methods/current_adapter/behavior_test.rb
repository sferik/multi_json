# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for current_adapter method behavior
class CurrentAdapterBehaviorTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_current_adapter_returns_value_not_nil
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter

    refute_nil result
    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_body_executes
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter

    refute_nil result
  end

  def test_current_adapter_uses_passed_options
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_accesses_options_bracket_adapter
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter({adapter: :json_gem})

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_uses_assignment_value
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter(adapter: :json_gem)

    refute_equal MultiJSON.adapter, result unless MultiJSON.adapter == MultiJSON::Adapters::JsonGem

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_does_not_raise
    result = MultiJSON.current_adapter

    refute_nil result
  end

  def test_current_adapter_instance_method_accepts_no_arguments
    MultiJSON.use :json_gem
    bound = MultiJSON.instance_method(:current_adapter).bind(MultiJSON)

    assert_equal MultiJSON::Adapters::JsonGem, bound.call
  end

  def test_current_adapter_instance_method_accepts_nil_options
    MultiJSON.use :json_gem
    object = Class.new { include MultiJSON }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJSON.send(:load_adapter, value) }
    object.send(:use, :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, object.send(:current_adapter, nil)
  end

  def test_current_adapter_instance_method_uses_adapter_option
    MultiJSON.use :json_gem
    object = Class.new { include MultiJSON }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJSON.send(:load_adapter, value) }

    result = object.send(:current_adapter, adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_uses_hash_literal_default_argument
    skip "RubyVM::InstructionSequence not available" unless defined?(RubyVM::InstructionSequence)

    iseq = RubyVM::InstructionSequence.of(MultiJSON.instance_method(:current_adapter))
    first_instruction = iseq.disasm.lines.find { |line| line.strip.start_with?("0000") }

    assert_includes first_instruction, "newhash"
    refute_includes first_instruction, "putnil"
  end

  def test_current_adapter_definition_includes_default_hash_argument
    file, = MultiJSON.instance_method(:current_adapter).source_location
    source = File.read(file)

    assert_includes source, "def current_adapter(options = {})"
  end
end
