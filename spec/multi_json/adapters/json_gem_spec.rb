require "spec_helper"
require "shared/adapter"
require "shared/json_common_adapter"
require "multi_json/adapters/json_gem"
require "open3"
require "rbconfig"
require "tempfile"

RSpec.describe MultiJson::Adapters::JsonGem, :json do
  it_behaves_like "an adapter", described_class
  it_behaves_like "JSON-like adapter", described_class

  context "when active_support/json is loaded" do
    let(:data) { {a: 1, b: 2, c: {d: {f: 2}}} }
    let(:expected_output) { "#{JSON.pretty_generate(data)}\n" }

    let(:script) do
      <<~RUBY
        $LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
        require "multi_json"
        require "multi_json/adapters/json_gem"
        require "active_support/json"

        data = {a: 1, b: 2, c: {d: {f: 2}}}

        puts MultiJson.dump(data, pretty: true, adapter: :json_gem)
      RUBY
    end

    it "prettifies output when :pretty is true" do
      Tempfile.create(["multi_json_json_gem", ".rb"]) do |file|
        file.write(script)
        file.flush
        file.close

        output, status = Open3.capture2(RbConfig.ruby, file.path)

        expect([status.success?, output]).to eq([true, expected_output])
      end
    end
  end
end
