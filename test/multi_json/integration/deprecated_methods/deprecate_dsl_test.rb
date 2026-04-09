require_relative "../../../test_helper"

# Tests the private deprecate_alias / deprecate_method helpers in
# `lib/multi_json/deprecated.rb` directly. The existing alias tests
# (decode_alias_test, engine_aliases_test, etc.) verify the
# already-generated methods, but mutant patches the helper definitions
# at runtime — the methods that were already produced at file-load time
# are unaffected by those mutations. These tests call the helpers
# during the test run so the mutated bodies actually execute.
module DeprecateDslTestHelpers
  def setup
    @registry = MultiJson.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @registry.clear
    @generated = []
    @original_warn = Kernel.method(:warn)
    @captured = []
    captured = @captured # closure capture so define_singleton_method on Kernel can write to it
    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| captured << msg } }
    MultiJson.define_singleton_method(:_dsl_capture) { |*args, **kwargs, &block| [args, kwargs, block&.call] }
    @generated << :_dsl_capture
  end

  def teardown
    silence_warnings { Kernel.define_singleton_method(:warn, @original_warn) }
    @generated.each { |name| remove_singleton_method(name) }
  end

  def remove_singleton_method(name)
    sclass = MultiJson.singleton_class
    return unless sclass.method_defined?(name) || sclass.private_method_defined?(name)

    sclass.send(:remove_method, name)
  end

  def unique_name
    name = :"_dsl_test_#{rand(1 << 30)}"
    @generated << name
    name
  end
end

class DeprecateAliasTest < Minitest::Test
  cover "MultiJson*"
  include DeprecateDslTestHelpers

  def test_defines_a_singleton_method
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    assert_respond_to MultiJson, name
  end

  def test_forwards_positional_arguments
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    args, _kwargs, _block = MultiJson.send(name, :a, :b)

    assert_equal %i[a b], args
  end

  def test_forwards_keyword_arguments
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    _args, kwargs, _block = MultiJson.send(name, foo: 1, bar: 2)

    assert_equal({foo: 1, bar: 2}, kwargs)
  end

  def test_forwards_block
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    _args, _kwargs, block_value = MultiJson.send(name) { :block_called }

    assert_equal :block_called, block_value
  end

  def test_returns_replacement_value
    name = unique_name
    MultiJson.define_singleton_method(:_dsl_doubled) { |x| x * 2 }
    @generated << :_dsl_doubled
    MultiJson.send(:deprecate_alias, name, :_dsl_doubled)

    assert_equal 14, MultiJson.send(name, 7)
  end

  def test_emits_warning_naming_target_method
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    MultiJson.send(name)

    assert_includes @captured.first, "MultiJson.#{name}"
  end

  def test_emits_warning_naming_replacement
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    MultiJson.send(name)

    assert_includes @captured.first, "MultiJson._dsl_capture"
  end

  def test_warning_mentions_v2_removal
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    MultiJson.send(name)

    assert_includes @captured.first, "v2.0"
  end

  def test_warns_only_once
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    3.times { MultiJson.send(name) }

    assert_equal 1, @captured.size
  end

  def test_keys_warning_by_alias_name
    name = unique_name
    MultiJson.send(:deprecate_alias, name, :_dsl_capture)

    MultiJson.send(name)

    assert_includes @registry, name
  end
end

class DeprecateMethodTest < Minitest::Test
  cover "MultiJson*"
  include DeprecateDslTestHelpers

  def test_defines_a_singleton_method
    name = unique_name
    MultiJson.send(:deprecate_method, name, "msg") { :body }

    assert_respond_to MultiJson, name
  end

  def test_invokes_block_body
    name = unique_name
    invoked = false
    MultiJson.send(:deprecate_method, name, "msg") { invoked = true }

    MultiJson.send(name)

    assert invoked
  end

  def test_returns_block_result
    name = unique_name
    MultiJson.send(:deprecate_method, name, "msg") { :result_value }

    assert_equal :result_value, MultiJson.send(name)
  end

  def test_forwards_positional_arguments_to_block
    name = unique_name
    received = nil
    MultiJson.send(:deprecate_method, name, "msg") { |*args| received = args }

    MultiJson.send(name, :one, :two)

    assert_equal %i[one two], received
  end

  def test_forwards_keyword_arguments_to_block
    name = unique_name
    received = nil
    MultiJson.send(:deprecate_method, name, "msg") { |**kwargs| received = kwargs }

    MultiJson.send(name, foo: 1)

    assert_equal({foo: 1}, received)
  end

  def test_emits_supplied_message
    name = unique_name
    MultiJson.send(:deprecate_method, name, "custom message text") { nil }

    MultiJson.send(name)

    assert_equal "custom message text", @captured.first
  end

  def test_warns_only_once
    name = unique_name
    MultiJson.send(:deprecate_method, name, "msg") { nil }

    3.times { MultiJson.send(name) }

    assert_equal 1, @captured.size
  end

  def test_keys_warning_by_method_name
    name = unique_name
    MultiJson.send(:deprecate_method, name, "msg") { nil }

    MultiJson.send(name)

    assert_includes @registry, name
  end
end
