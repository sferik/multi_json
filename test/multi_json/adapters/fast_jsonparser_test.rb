require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.fast_jsonparser?
  require "multi_json/adapters/fast_jsonparser"

  class FastJsonparserAdapterTest < Minitest::Test
    include AdapterTests

    def adapter_class
      MultiJson::Adapters::FastJsonparser
    end
  end
end
