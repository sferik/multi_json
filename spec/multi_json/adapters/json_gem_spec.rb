require "spec_helper"
require "shared/adapter"
require "shared/json_common_adapter"
require "multi_json/adapters/json_gem"

RSpec.describe MultiJson::Adapters::JsonGem, :json do
  it_behaves_like "an adapter", described_class
  it_behaves_like "JSON-like adapter", described_class

  context "when active_support/json is loaded" do
    it "prettifies output when :pretty is true" do
      require "active_support/json"

      data = {a: 1, b: 2, c: {d: {f: 2}}}

      expect(MultiJson.dump(data, pretty: true)).to eq(JSON.pretty_generate(data))
    end
  end
end
