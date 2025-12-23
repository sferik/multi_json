require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.gson?
  require "multi_json/adapters/gson"

  class GsonAdapterTest < Minitest::Test
    include AdapterTests

    def adapter_class
      MultiJson::Adapters::Gson
    end
  end
end
