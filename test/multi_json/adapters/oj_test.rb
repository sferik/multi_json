# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.oj?
  require "multi_json/adapters/oj"

  class OjAdapterTest < Minitest::Test
    cover "MultiJSON::Adapters::Oj*"

    include AdapterTests

    def adapter_class
      MultiJSON::Adapters::Oj
    end

    def test_dump_ensures_indent_is_fixnum
      with_default_options do
        # Should not raise an error
        MultiJSON.generate(42, indent: "")
      end
    end

    def test_oj_does_not_create_symbols_on_parse
      MultiJSON.parse('{"json_class":"ZOMG"}')
      original_count = Symbol.all_symbols.count
      MultiJSON.parse('{"json_class":"OMG"}')

      assert_operator Symbol.all_symbols.count, :<=, original_count
    end

    def test_ignores_oj_global_settings
      original_options = Oj.default_options
      Oj.default_options = {symbol_keys: true}

      example = '{"a": 1, "b": 2}'
      expected = {"a" => 1, "b" => 2}

      assert_equal expected, MultiJSON.parse(example)
    ensure
      Oj.default_options = original_options
    end

    def test_load_does_not_mutate_cached_options
      MultiJSON.parse_options = nil
      MultiJSON::OptionsCache.reset

      MultiJSON.parse('{"a":1}', symbolize_names: true)
      MultiJSON.parse('{"a":1}', symbolize_names: true)

      cached = MultiJSON::OptionsCache.load.send(:instance_variable_get, :@cache).values.first

      refute_includes cached.keys, :symbol_keys,
        "expected cached load options to be unchanged by Oj#load translation"
    end

    def test_dump_does_not_mutate_cached_options_with_pretty
      MultiJSON.generate_options = MultiJSON.adapter.generate_options = nil
      MultiJSON::OptionsCache.reset

      MultiJSON.generate({foo: "bar"}, pretty: true)

      cached = MultiJSON::OptionsCache.dump.send(:instance_variable_get, :@cache).values.first

      assert_includes cached.keys, :pretty,
        "expected cached dump options to retain :pretty key"
      refute_includes cached.keys, :indent,
        "expected cached dump options to NOT have prototype keys merged in"
    end
  end
end
