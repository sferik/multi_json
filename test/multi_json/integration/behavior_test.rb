# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "adapter_selection_test"

class BehaviorIntegrationTest < Minitest::Test
  cover "MultiJSON*"

  include IntegrationTestSetup

  def test_defaults_to_json_gem_when_no_adapters_available
    simulate_no_adapters do
      clear_default_adapter_warning

      capture_stderr { assert_equal :json_gem, MultiJSON.default_adapter }
    end
  end

  def test_finds_installable_adapter_when_none_preloaded
    # Undefine adapter constants so loaded_adapter returns nil,
    # but keep REQUIREMENT_MAP intact so installable_adapter can require them
    undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser) do
      clear_default_adapter_warning

      # This will trigger installable_adapter since no constants are defined
      adapter = capture_stderr { MultiJSON.default_adapter }

      # Should find the first installable adapter from REQUIREMENT_MAP
      assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], adapter
    end
  end

  def test_prints_warning_when_no_adapters_available
    simulate_no_adapters { assert_warns_about_no_adapters(times: 1) }
  end

  def test_warns_only_once_when_no_adapters_available
    simulate_no_adapters { assert_warns_about_no_adapters(times: 1) { MultiJSON.default_adapter } }
  end

  def test_fallback_adapter_skips_warning_when_already_shown
    simulate_no_adapters do
      clear_default_adapter_warning

      # First call - shows warning and sets @default_adapter_warning_shown
      capture_stderr { MultiJSON.default_adapter }

      # Clear @default_adapter but keep @default_adapter_warning_shown
      clear_default_adapter_caches

      # Second call should NOT warn (exercises else branch at line 17)
      assert_equal(0, warning_count_for { MultiJSON.default_adapter })
    end
  end

  def test_busts_caches_on_global_options_change
    MultiJSON.use MultiJSON::Adapters::JsonGem
    assert_cache_busting { |val| MultiJSON.parse_options = val }
  end

  def test_busts_caches_on_per_adapter_options_change
    adapter = MultiJSON::Adapters::JsonGem
    MultiJSON.use adapter
    assert_cache_busting { |val| adapter.parse_options = val }
  end

  def test_one_shot_parser_uses_defined_parser_for_call
    MultiJSON.use :json_gem

    assert_one_shot_adapter_behavior
  end

  def test_json_gem_does_not_create_symbols_on_parse
    MultiJSON.with_adapter(:json_gem) do
      MultiJSON.parse('{"json_class":"ZOMG"}')
      original_count = Symbol.all_symbols.count
      MultiJSON.parse('{"json_class":"OMG"}')

      assert_operator Symbol.all_symbols.count, :<=, original_count
    end
  end

  private

  def assert_warns_about_no_adapters(times:)
    clear_default_adapter_warning
    warning_count = warning_count_for do
      MultiJSON.default_adapter
      yield if block_given?
    end

    assert_equal times, warning_count
  end

  def assert_cache_busting
    json_string = '{"abc":"def"}'
    yield({symbolize_names: true})

    assert_equal({abc: "def"}, MultiJSON.parse(json_string))
    yield(nil)

    assert_equal({"abc" => "def"}, MultiJSON.parse(json_string))
  end

  def assert_one_shot_adapter_behavior
    results = track_json_gem_calls { verify_one_shot_dump_and_load }

    assert results[:generate_called] && results[:parse_called]
    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def clear_default_adapter_caches
    %i[@default_adapter @default_parse_adapter @default_generate_adapter].each do |ivar|
      MultiJSON.remove_instance_variable(ivar) if MultiJSON.instance_variable_defined?(ivar)
    end
  end

  def warning_count_for(&block)
    warn_count = 0
    with_stub(Kernel, :warn, ->(msg, **) { warn_count += 1 if /warning/i.match?(msg) }) { block.call }
    warn_count
  end

  def track_json_gem_calls(&)
    results = {generate_called: false, parse_called: false}
    dump_stub = ->(*) { (results[:generate_called] = true) && "dump_something" }
    load_stub = ->(*) { (results[:parse_called] = true) && "load_something" }
    with_stub(MultiJSON::Adapters::JsonGem, :generate, dump_stub) do
      with_stub(MultiJSON::Adapters::JsonGem, :parse, load_stub, &)
    end
    results
  end

  def verify_one_shot_dump_and_load
    assert_equal "dump_something", MultiJSON.generate("", adapter: :json_gem)
    assert_equal "load_something", MultiJSON.parse("", adapter: :json_gem)
  end
end
