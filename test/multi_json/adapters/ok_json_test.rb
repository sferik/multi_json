require_relative "../../test_helper"
require_relative "../../support/adapter_tests"
require "multi_json/adapters/ok_json"

class OkJsonAdapterTest < Minitest::Test
  include AdapterTests

  def adapter_class
    MultiJson::Adapters::OkJson
  end
end
