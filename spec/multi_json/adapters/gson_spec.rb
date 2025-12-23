require "spec_helper"
require "shared/adapter"

if RSpec.configuration.gson?
  require "multi_json/adapters/gson"

  RSpec.describe MultiJson::Adapters::Gson, :gson do
    it_behaves_like "an adapter", described_class
  end
end
