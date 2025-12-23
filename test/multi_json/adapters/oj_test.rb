require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.oj?
  require "multi_json/adapters/oj"

  class OjAdapterTest < Minitest::Test
    include AdapterTests

    def adapter_class
      MultiJson::Adapters::Oj
    end

    def test_dump_ensures_indent_is_fixnum
      with_default_options do
        # Should not raise an error
        MultiJson.dump(42, indent: "")
      end
    end

    def test_oj_does_not_create_symbols_on_parse
      MultiJson.load('{"json_class":"ZOMG"}')
      original_count = Symbol.all_symbols.count
      MultiJson.load('{"json_class":"OMG"}')

      assert_equal original_count, Symbol.all_symbols.count
    end

    def test_ignores_oj_global_settings
      original_options = Oj.default_options
      Oj.default_options = {symbol_keys: true}

      example = '{"a": 1, "b": 2}'
      expected = {"a" => 1, "b" => 2}

      assert_equal expected, MultiJson.load(example)
    ensure
      Oj.default_options = original_options
    end
  end
end
