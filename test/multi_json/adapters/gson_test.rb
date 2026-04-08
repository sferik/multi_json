require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.gson?
  require "multi_json/adapters/gson"

  class GsonAdapterTest < Minitest::Test
    cover "MultiJson::Adapters::Gson*"

    include AdapterTests

    def adapter_class
      MultiJson::Adapters::Gson
    end
  end
end
