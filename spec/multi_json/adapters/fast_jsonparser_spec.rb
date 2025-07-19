require "spec_helper"
return unless RSpec.configuration.fast_jsonparser?

require "shared/adapter"
require "multi_json/adapters/fast_jsonparser"

RSpec.describe MultiJson::Adapters::FastJsonparser, :fast_jsonparser do
  it_behaves_like "an adapter", described_class
end
