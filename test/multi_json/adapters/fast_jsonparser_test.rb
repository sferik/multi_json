# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.fast_jsonparser?
  require "multi_json/adapters/fast_jsonparser"

  class FastJsonparserAdapterTest < Minitest::Test
    cover "MultiJSON::Adapters::FastJsonparser*"

    include AdapterTests

    def adapter_class
      MultiJSON::Adapters::FastJsonparser
    end
  end
end
