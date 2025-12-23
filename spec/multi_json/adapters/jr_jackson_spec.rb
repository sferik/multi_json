require "spec_helper"
require "shared/adapter"

if RSpec.configuration.jrjackson?
  require "multi_json/adapters/jr_jackson"

  RSpec.describe MultiJson::Adapters::JrJackson, :jrjackson do
    it_behaves_like "an adapter", described_class
  end
end
