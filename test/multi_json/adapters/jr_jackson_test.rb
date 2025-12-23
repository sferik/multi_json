require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.jrjackson?
  require "multi_json/adapters/jr_jackson"

  class JrJacksonAdapterTest < Minitest::Test
    cover "MultiJson*"

    include AdapterTests

    def adapter_class
      MultiJson::Adapters::JrJackson
    end
  end
end
