require "spec_helper"
require "shared/adapter"

if RSpec.configuration.yajl?
  require "multi_json/adapters/yajl"

  RSpec.describe MultiJson::Adapters::Yajl, :yajl do
    it_behaves_like "an adapter", described_class
  end
end
