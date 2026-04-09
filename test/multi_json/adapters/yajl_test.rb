# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/adapter_tests"

if TestHelpers.yajl?
  require "multi_json/adapters/yajl"

  class YajlAdapterTest < Minitest::Test
    cover "MultiJson::Adapters::Yajl*"

    include AdapterTests

    def adapter_class
      MultiJson::Adapters::Yajl
    end
  end
end
