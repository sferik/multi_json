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
    before { MultiJson.use described_class }

    it "calls as_json on objects that respond to it" do
      klass = Class.new do
        def as_json(*)
          {abc: "def"}
        end
      end
      object = klass.new
      allow(object).to receive(:as_json).and_call_original
      MultiJson.dump(object)
      expect(object).to have_received(:as_json)
    end

    it "calls as_json on objects that respond to it with pretty option" do
      klass = Class.new do
        def as_json(*)
          {abc: "def"}
        end
      end
      object = klass.new
      allow(object).to receive(:as_json).and_call_original
      MultiJson.dump(object, pretty: true)
      expect(object).to have_received(:as_json)
    end
  end

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

    def run_script(script_content)
      Tempfile.create(["multi_json_json_gem", ".rb"]) do |file|
        file.write(script_content)
        file.flush
        file.close

        Open3.capture2(RbConfig.ruby, file.path)
      end
    end

    it "prettifies output when :pretty is true" do
      output, status = run_script(script)

      expect([status.success?, output]).to eq([true, expected_output])
    end

    it "serializes objects that define to_hash" do
      script = <<~RUBY
        $LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
        require "multi_json"
        require "multi_json/adapters/json_gem"
        require "active_support/json"

        class MyClass
          def to_hash
            {abc: "def"}
          end
        end

        puts MultiJson.dump(MyClass.new, adapter: :json_gem)
      RUBY

      output, status = run_script(script)

      expect([status.success?, output]).to eq([true, "{\"abc\":\"def\"}\n"])
    end

    it "serializes Time objects using ActiveSupport format" do
      script = <<~RUBY
        $LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
        require "multi_json"
        require "multi_json/adapters/json_gem"
        require "active_support/json"

        time = Time.utc(2025, 12, 4, 13, 39, 46, 705000)
        puts MultiJson.dump(time, adapter: :json_gem)
      RUBY

      output, status = run_script(script)

      expect(status.success?).to be(true)
      expect(output).to include("2025-12-04T13:39:46.705Z")
    end
  end
end
