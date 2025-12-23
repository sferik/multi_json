require "spec_helper"
require "shared/adapter"

if RSpec.configuration.fast_jsonparser?
  require "multi_json/adapters/fast_jsonparser"

  RSpec.describe MultiJson::Adapters::FastJsonparser, :fast_jsonparser do
    it_behaves_like "an adapter", described_class
  end
end
