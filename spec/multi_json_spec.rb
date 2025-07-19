require "spec_helper"
require "shared/options"

RSpec.configure do |config|
  config.before(:suite) do
    # make sure all available libs are required
    MultiJson::REQUIREMENT_MAP.each_value do |library|
      require library
    rescue LoadError
      next
    end
  end
end

RSpec.describe MultiJson do
  let(:config) { RSpec.configuration }

  before do
    described_class.use :oj
    skip "java based implementations" if config.java?
  end

  context "when no other json implementations are available" do
    around do |example|
      simulate_no_adapters { example.call }
    end

    before do
      if described_class.instance_variable_defined?(:@default_adapter_warning_shown)
        described_class.remove_instance_variable(:@default_adapter_warning_shown)
      end
    end

    after do
      if described_class.instance_variable_defined?(:@default_adapter_warning_shown)
        described_class.remove_instance_variable(:@default_adapter_warning_shown)
      end
    end

    it "defaults to ok_json if no other json implementions are available" do
      silence_warnings do
        expect(described_class.default_adapter).to eq(:ok_json)
      end
    end

    it "prints a warning" do
      allow(Kernel).to receive(:warn)
      described_class.default_adapter
      expect(Kernel).to have_received(:warn).with(/warning/i)
    end

    it "warns only once" do
      allow(Kernel).to receive(:warn)
      described_class.default_adapter
      described_class.default_adapter
      expect(Kernel).to have_received(:warn).once
    end
  end

  context "when JSON pure is already loaded" do
    before do
      expect(JSON::JSON_LOADED).to be_truthy
      @ext = JSON::Ext::Parser if defined?(JSON::Ext::Parser)
      hide_const("JSON::Ext::Parser")
      allow(described_class).to receive(:require)
    end

    after { stub_const("JSON::Ext::Parser", @ext) if @ext }

    it "default_adapter tries to require each adapter in turn", :aggregate_failures do
      undefine_constants(:Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser) do
        described_class.default_adapter
        expect(described_class).to have_received(:require)
      end
    end
  end

  context "when caching" do
    before { described_class.use adapter }

    let(:adapter) { MultiJson::Adapters::JsonGem }
    let(:json_string) { '{"abc":"def"}' }

    it "busts caches on global options change", :aggregate_failures do
      described_class.load_options = {symbolize_keys: true}
      expect(described_class.load(json_string)).to eq(abc: "def")
      described_class.load_options = nil
      expect(described_class.load(json_string)).to eq("abc" => "def")
    end

    it "busts caches on per-adapter options change", :aggregate_failures do
      adapter.load_options = {symbolize_keys: true}
      expect(described_class.load(json_string)).to eq(abc: "def")
      adapter.load_options = nil
      expect(described_class.load(json_string)).to eq("abc" => "def")
    end
  end

  context "when automatically loading adapter" do
    before do
      described_class.send(:remove_instance_variable, :@adapter) if described_class.instance_variable_defined?(:@adapter)
    end

    let(:expected_adapter) do
      if config.java? && config.jrjackson?
        "MultiJson::Adapters::JrJackson"
      elsif config.java? && config.json?
        "MultiJson::Adapters::JsonGem"
      elsif config.fast_jsonparser?
        "MultiJson::Adapters::FastJsonparser"
      else
        "MultiJson::Adapters::Oj"
      end
    end

    it "defaults to the best available gem" do
      expect(described_class.adapter.to_s).to eq(expected_adapter)
    end

    it "looks for adapter even if @adapter variable is nil" do
      allow(described_class).to receive(:default_adapter).and_return(:ok_json)
      expect(described_class.adapter).to eq(MultiJson::Adapters::OkJson)
    end
  end

  it "is settable via a symbol" do
    described_class.use :json_gem
    expect(described_class.adapter).to eq(MultiJson::Adapters::JsonGem)
  end

  it "is settable via a case-insensitive string" do
    described_class.use "Json_Gem"
    expect(described_class.adapter).to eq(MultiJson::Adapters::JsonGem)
  end

  it "is settable via a class" do
    adapter = Class.new
    described_class.use adapter
    expect(described_class.adapter).to eq(adapter)
  end

  it "is settable via a module" do
    adapter = Module.new
    described_class.use adapter
    expect(described_class.adapter).to eq(adapter)
  end

  it "throws AdapterError on bad input" do
    expect { described_class.use "bad adapter" }.to raise_error(MultiJson::AdapterError, /bad adapter/)
  end

  it "gives access to original error when raising AdapterError", :aggregate_failures do
    exception = get_exception(MultiJson::AdapterError) { described_class.use "foobar" }
    expect(exception.cause).to be_instance_of(LoadError)
    expect(exception.message).to include("-- multi_json/adapters/foobar")
    expect(exception.message).to include("Did not recognize your adapter specification")
  end

  context "with one-shot parser" do
    before do
      allow(MultiJson::Adapters::OkJson).to receive_messages(dump: "dump_something", load: "load_something")
      described_class.use :json_gem
    end

    it "uses the defined parser just for the call", :aggregate_failures do
      expect(described_class.dump("", adapter: :ok_json)).to eq("dump_something")
      expect(described_class.load("", adapter: :ok_json)).to eq("load_something")
      expect(MultiJson::Adapters::OkJson).to have_received(:dump)
      expect(MultiJson::Adapters::OkJson).to have_received(:load)
      expect(described_class.adapter).to eq(MultiJson::Adapters::JsonGem)
    end
  end

  it "can set adapter for a block", :aggregate_failures do
    described_class.with_adapter(:json_gem) do
      described_class.with_engine(:ok_json) { expect(described_class.adapter).to eq(MultiJson::Adapters::OkJson) }
      expect(described_class.adapter).to eq(MultiJson::Adapters::JsonGem)
    end
    expect(described_class.adapter).to eq(MultiJson::Adapters::Oj)
  end

  it "restores adapter after an exception", :aggregate_failures do
    described_class.use :json_gem
    expect do
      expect { described_class.with_adapter(:oj) { raise StandardError } }.to raise_error(StandardError)
    end.not_to change(described_class, :adapter)
  end

  it "JSON gem does not create symbols on parse" do
    described_class.with_engine(:json_gem) do
      described_class.load('{"json_class":"ZOMG"}')
      expect { described_class.load('{"json_class":"OMG"}') }.not_to(change { Symbol.all_symbols.count })
    end
  end

  describe "default options" do
    around do |example|
      example.run
      described_class.load_options = described_class.dump_options = nil
    end

    it "is deprecated" do
      allow(Kernel).to receive(:warn)
      silence_warnings { described_class.default_options = {foo: "bar"} }
      expect(Kernel).to have_received(:warn).with(/deprecated/i)
    end

    it "sets both load and dump options", :aggregate_failures do
      allow(described_class).to receive(:dump_options=)
      allow(described_class).to receive(:load_options=)
      silence_warnings { described_class.default_options = {foo: "bar"} }
      expect(described_class).to have_received(:dump_options=).with({foo: "bar"})
      expect(described_class).to have_received(:load_options=).with({foo: "bar"})
    end
  end

  it_behaves_like "has options", described_class

  describe "aliases", :jrjackson do
    describe "jrjackson" do
      it "allows jrjackson alias as symbol", :aggregate_failures do
        expect { described_class.use :jrjackson }.not_to raise_error
        expect(described_class.adapter).to eq(MultiJson::Adapters::JrJackson)
      end

      it "allows jrjackson alias as string", :aggregate_failures do
        expect { described_class.use "jrjackson" }.not_to raise_error
        expect(described_class.adapter).to eq(MultiJson::Adapters::JrJackson)
      end
    end
  end
end
