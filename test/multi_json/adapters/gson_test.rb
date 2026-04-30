# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.gson?
  require "multi_json/adapters/gson"

  class GsonAdapterTest < Minitest::Test
    cover "MultiJSON::Adapters::Gson*"

    include AdapterTests

    def adapter_class
      MultiJSON::Adapters::Gson
    end

    # Exercises the non-empty-options branch in Gson#dump that the
    # shared adapter tests skip — they pass an :adapter override that
    # routes the dump through json_gem instead. ``:html_safe`` is one
    # of the option keys Gson::Encoder.new accepts directly.
    def test_dump_with_options_allocates_a_fresh_encoder
      result = MultiJSON::Adapters::Gson.dump({a: 1}, html_safe: true)

      assert_kind_of String, result
      assert_includes result, "\"a\""
    end
  end
end
