require_relative "../test_helper"
require "multi_json/adapters/json_gem"
require "stringio"

class AdapterInheritanceTest < Minitest::Test
  cover "MultiJson::Adapter*"

  def test_subclass_inherits_parent_default_load_options
    parent = Class.new(MultiJson::Adapter) do
      defaults :load, {symbolize_keys: true}
    end

    child = Class.new(parent)

    assert_equal({symbolize_keys: true}, child.default_load_options)
  end

  def test_subclass_inherits_parent_default_dump_options
    parent = Class.new(MultiJson::Adapter) do
      defaults :dump, {pretty: true}
    end

    child = Class.new(parent)

    assert_equal({pretty: true}, child.default_dump_options)
  end

  def test_subclass_without_default_options_falls_back_to_empty
    parent = Class.new(MultiJson::Adapter)
    child = Class.new(parent)

    assert_empty(child.default_load_options)
    assert_empty(child.default_dump_options)
  end

  def test_default_load_options_propagates_after_subclass_definition
    parent = Class.new(MultiJson::Adapter)
    child = Class.new(parent)
    parent.defaults :load, {symbolize_keys: true}

    assert_equal({symbolize_keys: true}, child.default_load_options)
  end

  def test_default_dump_options_propagates_after_subclass_definition
    parent = Class.new(MultiJson::Adapter)
    child = Class.new(parent)
    parent.defaults :dump, {pretty: true}

    assert_equal({pretty: true}, child.default_dump_options)
  end

  def test_subclass_default_load_options_overrides_parent
    parent = Class.new(MultiJson::Adapter) { defaults :load, {symbolize_keys: true} }
    child = Class.new(parent) { defaults :load, {symbolize_keys: false} }

    assert_equal({symbolize_keys: false}, child.default_load_options)
    assert_equal({symbolize_keys: true}, parent.default_load_options)
  end
end

class AdapterLoadTest < Minitest::Test
  cover "MultiJson::Adapter*"

  def test_load_returns_nil_for_nil_input
    assert_nil MultiJson::Adapters::JsonGem.load(nil)
  end

  def test_load_returns_nil_for_empty_string
    assert_nil MultiJson::Adapters::JsonGem.load("")
  end

  def test_load_returns_nil_for_whitespace_only_string
    assert_nil MultiJson::Adapters::JsonGem.load("   \n\t  ")
  end

  def test_load_reads_from_io_object
    io = StringIO.new('{"key": "value"}')
    result = MultiJson::Adapters::JsonGem.load(io)

    assert_equal({"key" => "value"}, result)
  end

  def test_load_parses_valid_json
    result = MultiJson::Adapters::JsonGem.load('{"name": "test"}')

    assert_equal({"name" => "test"}, result)
  end

  def test_load_with_symbolize_keys_option
    result = MultiJson::Adapters::JsonGem.load('{"name": "test"}', symbolize_keys: true)

    assert_equal({name: "test"}, result)
  end

  def test_load_handles_invalid_utf8_in_blank_check
    # Invalid UTF-8 byte sequence that triggers ArgumentError in blank? regex
    # The blank? method rescues ArgumentError and returns false, allowing parse to proceed
    # This test verifies blank? doesn't crash on invalid UTF-8
    invalid_utf8 = (+"\xFF\xFE").force_encoding("UTF-8")

    # Should raise parse error, not ArgumentError from blank check
    assert_raises(JSON::ParserError) do
      MultiJson::Adapters::JsonGem.load(invalid_utf8)
    end
  end
end

class AdapterDumpTest < Minitest::Test
  cover "MultiJson::Adapter*"

  def test_dump_converts_hash_to_json
    result = MultiJson::Adapters::JsonGem.dump({name: "test"})

    assert_equal '{"name":"test"}', result
  end

  def test_dump_converts_array_to_json
    result = MultiJson::Adapters::JsonGem.dump([1, 2, 3])

    assert_equal "[1,2,3]", result
  end

  def test_dump_with_adapter_option_strips_adapter_from_cached_options
    result = MultiJson::Adapters::JsonGem.dump({key: "value"}, adapter: :oj)

    assert_equal '{"key":"value"}', result
  end

  def test_dump_with_json_state_options
    # JSON gem 2.x passes JSON::State objects which don't respond to Hash methods
    # like #except - ensure we convert to Hash first (GitHub issue #59)
    state = JSON::State.new(indent: "  ")
    result = MultiJson::Adapters::JsonGem.dump({key: "value"}, state)

    assert_includes result, "key"
    assert_includes result, "value"
  end

  def test_dump_with_object_responding_to_to_h
    # Test that any object responding to #to_h works as options
    options_like = Struct.new(:indent).new("  ")
    def options_like.to_h = {indent: indent}

    result = MultiJson::Adapters::JsonGem.dump({key: "value"}, options_like)

    assert_includes result, "key"
    assert_includes result, "value"
  end
end

class AdapterDefaultsTest < Minitest::Test
  cover "MultiJson::Adapter*"

  def test_defaults_sets_load_options
    adapter = Class.new(MultiJson::Adapter) do
      defaults :load, {symbolize_keys: true}
    end

    assert_equal({symbolize_keys: true}, adapter.default_load_options)
  end

  def test_defaults_sets_dump_options
    adapter = Class.new(MultiJson::Adapter) do
      defaults :dump, {pretty: true}
    end

    assert_equal({pretty: true}, adapter.default_dump_options)
  end

  def test_defaults_freezes_options
    adapter = Class.new(MultiJson::Adapter) do
      defaults :load, {foo: :bar}
    end

    assert_predicate adapter.default_load_options, :frozen?
  end

  def test_defaults_raises_on_unknown_action
    error = assert_raises(ArgumentError) do
      Class.new(MultiJson::Adapter) { defaults :encode, {foo: :bar} }
    end

    assert_match(/:load or :dump/, error.message)
    assert_match(/:encode/, error.message)
  end

  def test_defaults_raises_on_non_hash_value
    error = assert_raises(ArgumentError) do
      Class.new(MultiJson::Adapter) { defaults :load, "not a hash" }
    end

    assert_match(/Hash/, error.message)
  end
end

class AdapterCachedOptionsTest < Minitest::Test
  cover "MultiJson::Adapter*"

  def test_cached_options_merges_adapter_and_global_options
    MultiJson.use :json_gem
    MultiJson::OptionsCache.reset

    # Set global options
    original_load_options = MultiJson.load_options
    MultiJson.load_options = {symbolize_keys: true}

    result = MultiJson::Adapters::JsonGem.load('{"key": "value"}')

    assert_equal({key: "value"}, result)
  ensure
    MultiJson.load_options = original_load_options
  end

  def test_options_without_adapter_freezes_result
    MultiJson.use :json_gem
    MultiJson::OptionsCache.reset

    MultiJson::Adapters::JsonGem.load("{}", symbolize_keys: true)
    cache = MultiJson::OptionsCache.load.instance_variable_get(:@cache)

    refute_empty cache
  end
end
