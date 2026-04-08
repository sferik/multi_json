require_relative "../../test_helper"
require_relative "adapter_selection_test"

class BehaviorIntegrationTest < Minitest::Test
  cover "MultiJson*"

  include IntegrationTestSetup

  def test_defaults_to_json_gem_when_no_adapters_available
    simulate_no_adapters do
      clear_default_adapter_warning

      capture_stderr { assert_equal :json_gem, MultiJson.default_adapter }
    end
  end

  def test_finds_installable_adapter_when_none_preloaded
    # Undefine adapter constants so loaded_adapter returns nil,
    # but keep REQUIREMENT_MAP intact so installable_adapter can require them
    undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser) do
      clear_default_adapter_warning

      # This will trigger installable_adapter since no constants are defined
      adapter = capture_stderr { MultiJson.default_adapter }

      # Should find the first installable adapter from REQUIREMENT_MAP
      assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], adapter
    end
  end

  def test_prints_warning_when_no_adapters_available
    simulate_no_adapters { assert_warns_about_no_adapters(times: 1) }
  end

  def test_warns_only_once_when_no_adapters_available
    simulate_no_adapters { assert_warns_about_no_adapters(times: 1) { MultiJson.default_adapter } }
  end

  def test_fallback_adapter_skips_warning_when_already_shown
    simulate_no_adapters do
      clear_default_adapter_warning

      # First call - shows warning and sets @default_adapter_warning_shown
      capture_stderr { MultiJson.default_adapter }

      # Clear @default_adapter but keep @default_adapter_warning_shown
      MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)

      # Second call should NOT warn (exercises else branch at line 17)
      warn_count = 0
      with_stub(Kernel, :warn, ->(msg) { warn_count += 1 if /warning/i.match?(msg) }) do
        MultiJson.default_adapter
      end

      assert_equal 0, warn_count
    end
  end

  def test_busts_caches_on_global_options_change
    MultiJson.use MultiJson::Adapters::JsonGem
    assert_cache_busting { |val| MultiJson.load_options = val }
  end

  def test_busts_caches_on_per_adapter_options_change
    adapter = MultiJson::Adapters::JsonGem
    MultiJson.use adapter
    assert_cache_busting { |val| adapter.load_options = val }
  end

  def test_one_shot_parser_uses_defined_parser_for_call
    MultiJson.use :json_gem

    assert_one_shot_adapter_behavior
  end

  def test_json_gem_does_not_create_symbols_on_parse
    MultiJson.with_engine(:json_gem) do
      MultiJson.load('{"json_class":"ZOMG"}')
      original_count = Symbol.all_symbols.count
      MultiJson.load('{"json_class":"OMG"}')

      assert_equal original_count, Symbol.all_symbols.count
    end
  end

  private

  def assert_warns_about_no_adapters(times:)
    clear_default_adapter_warning
    warn_count = 0
    with_stub(Kernel, :warn, ->(msg) { warn_count += 1 if /warning/i.match?(msg) }) do
      MultiJson.default_adapter
      yield if block_given?
    end

    assert_equal times, warn_count
  end

  def assert_cache_busting
    json_string = '{"abc":"def"}'
    yield({symbolize_keys: true})

    assert_equal({abc: "def"}, MultiJson.load(json_string))
    yield(nil)

    assert_equal({"abc" => "def"}, MultiJson.load(json_string))
  end

  def assert_one_shot_adapter_behavior
    results = track_json_gem_calls { verify_one_shot_dump_and_load }

    assert results[:dump_called] && results[:load_called]
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def track_json_gem_calls(&)
    results = {dump_called: false, load_called: false}
    dump_stub = ->(*) { (results[:dump_called] = true) && "dump_something" }
    load_stub = ->(*) { (results[:load_called] = true) && "load_something" }
    with_stub(MultiJson::Adapters::JsonGem, :dump, dump_stub) do
      with_stub(MultiJson::Adapters::JsonGem, :load, load_stub, &)
    end
    results
  end

  def verify_one_shot_dump_and_load
    assert_equal "dump_something", MultiJson.dump("", adapter: :json_gem)
    assert_equal "load_something", MultiJson.load("", adapter: :json_gem)
  end
end
