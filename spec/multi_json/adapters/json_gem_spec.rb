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

  describe ".dump" do
    let(:klass) { Class.new { def as_json(*) = {abc: "def"} } }
    let(:object) { klass.new }

    before do
      MultiJson.use described_class
      allow(object).to receive(:as_json).and_call_original
    end

    it "calls as_json on objects that respond to it" do
      MultiJson.dump(object)
      expect(object).to have_received(:as_json)
    end

    it "calls as_json on objects that respond to it with pretty option" do
      MultiJson.dump(object, pretty: true)
      expect(object).to have_received(:as_json)
    end
  end

  context "when active_support/json is loaded" do
    def run_script(script_content)
      Tempfile.create(["multi_json_json_gem", ".rb"]) do |file|
        file.write(script_content)
        file.flush
        file.close

        Open3.capture2(RbConfig.ruby, file.path)
      end
    end

    def activesupport_script(code)
      <<~RUBY
        $LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
        require "multi_json"
        require "multi_json/adapters/json_gem"
        require "active_support/json"

        #{code}
      RUBY
    end

    let(:pretty_script) { activesupport_script("puts MultiJson.dump({a: 1, b: 2, c: {d: {f: 2}}}, pretty: true, adapter: :json_gem)") }
    let(:to_hash_script) do
      activesupport_script('Class.new { def to_hash = {abc: "def"} }.then { puts MultiJson.dump(_1.new, adapter: :json_gem) }')
    end
    let(:time_script) { activesupport_script("puts MultiJson.dump(Time.utc(2025, 12, 4, 13, 39, 46, 705000), adapter: :json_gem)") }

    it "prettifies output when :pretty is true" do
      output, status = run_script(pretty_script)

      expect([status.success?, output]).to eq([true, "#{JSON.pretty_generate({a: 1, b: 2, c: {d: {f: 2}}})}\n"])
    end

    it "serializes objects that define to_hash" do
      output, status = run_script(to_hash_script)

      expect([status.success?, output]).to eq([true, "{\"abc\":\"def\"}\n"])
    end

    it "serializes Time objects using ActiveSupport format", :aggregate_failures do
      output, status = run_script(time_script)

      expect(status.success?).to be(true)
      expect(output).to include("2025-12-04T13:39:46.705Z")
    end
  end
end
