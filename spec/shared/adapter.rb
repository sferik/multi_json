require "shared/options"
require "stringio"

shared_examples_for "an adapter" do |adapter|
  before { MultiJson.use adapter }

  it_behaves_like "has options", adapter

  it "does not modify argument hashes when loading" do
    options = {symbolize_keys: true, pretty: false, adapter: :ok_json}
    expect { MultiJson.load("{}", options) }.not_to(change { options })
  end

  it "does not modify argument hashes when dumping" do
    options = {symbolize_keys: true, pretty: false, adapter: :ok_json}
    expect { MultiJson.dump([42], options) }.not_to(change { options })
  end

  describe ".dump" do
    describe "#dump_options" do
      before do
        MultiJson.dump_options = MultiJson.adapter.dump_options = {}
        MultiJson.adapter.dump_options = {foo: "foo"}
        MultiJson.dump_options = {foo: "bar"}
        allow(MultiJson.adapter.instance).to receive(:dump).and_call_original
       end

      after do
        MultiJson.dump_options = MultiJson.adapter.dump_options = nil
      end

      it "respects global dump options", :aggregate_failures do
        MultiJson.dump_options = {foo: "bar"}
        expect(MultiJson.dump_options).to eq({foo: "bar"})
        allow(MultiJson.adapter.instance).to receive(:dump).and_call_original
        MultiJson.dump(1, fizz: "buzz")
        expect(MultiJson.adapter.instance).to have_received(:dump).with(1, {foo: "bar", fizz: "buzz"})
      end

      it "respects per-adapter dump options", :aggregate_failures do
        MultiJson.adapter.dump_options = {foo: "bar"}
        expect(MultiJson.adapter.dump_options).to eq({foo: "bar"})
        allow(MultiJson.adapter.instance).to receive(:dump).and_call_original
        MultiJson.dump(1, fizz: "buzz")
        expect(MultiJson.adapter.instance).to have_received(:dump).with(1, {foo: "bar", fizz: "buzz"})
      end

      it "adapter-specific are overridden by global options", :aggregate_failures do
        MultiJson.dump(1, fizz: "buzz")
        expect(MultiJson.adapter.dump_options).to eq({foo: "foo"})
        expect(MultiJson.dump_options).to eq({foo: "bar"})
        expect(MultiJson.adapter.instance).to have_received(:dump).with(1, {foo: "bar", fizz: "buzz"})
      end
    end

    it "writes decodable JSON" do
      examples = [{"abc" => "def"}, [], 1, "2", true, false, nil]
      examples.each { |e| expect(MultiJson.load(MultiJson.dump(e))).to eq(e) }
    end

    it "dumps time in correct format" do
      time = Time.at(1_355_218_745).utc

      dumped_json = MultiJson.dump(time)
      expected = "2012-12-11 09:39:05 UTC"
      expect(MultiJson.load(dumped_json)).to eq(expected)
    end

    it "dumps symbol and fixnum keys as strings" do
      ex = [[{foo: {bar: "baz"}}, {"foo" => {"bar" => "baz"}}],
            [[{foo: {bar: "baz"}}], [{"foo" => {"bar" => "baz"}}]],
            [{foo: [{bar: "baz"}]}, {"foo" => [{"bar" => "baz"}]}],
            [{1 => {2 => {3 => "bar"}}}, {"1" => {"2" => {"3" => "bar"}}}]]
      ex.each { |v, exp| expect(MultiJson.load(MultiJson.dump(v))).to eq(exp) }
    end

    it "dumps rootless JSON", :aggregate_failures do
      expect(MultiJson.dump("random rootless string")).to eq('"random rootless string"')
      expect(MultiJson.dump(123)).to eq("123")
    end

    it "passes options to the adapter" do
      allow(MultiJson.adapter).to receive(:dump).and_call_original
      MultiJson.dump("foo", {bar: :baz})
      expect(MultiJson.adapter).to have_received(:dump).with("foo", {bar: :baz})
    end

    it "dumps custom objects that implement to_json" do
      pending "not supported" if adapter.name == "MultiJson::Adapters::Gson"
      klass = Class.new { def to_json(*) '"foobar"' end }
      expect(MultiJson.dump(klass.new)).to eq('"foobar"')
    end

    it "allows to dump JSON values" do
      expect(MultiJson.dump(42)).to eq("42")
    end

    it "allows to dump JSON with UTF-8 characters" do
      expect(MultiJson.dump("color" => "żółć")).to eq('{"color":"żółć"}')
    end
  end

  describe ".load" do
    describe "#load_options" do
      before do
        MultiJson.load_options = MultiJson.adapter.load_options = {}
        MultiJson.adapter.load_options = {foo: "foo"}
        MultiJson.load_options = {foo: "bar"}
        allow(MultiJson.adapter.instance).to receive(:load).and_call_original
         end

      after do
        MultiJson.load_options = MultiJson.adapter.load_options = nil
      end

      it "respects global load options", :aggregate_failures do
        MultiJson.load_options = {foo: "bar"}
        expect(MultiJson.load_options).to eq({foo: "bar"})
        allow(MultiJson.adapter.instance).to receive(:load).and_call_original
        MultiJson.load("1", fizz: "buzz")
        expect(MultiJson.adapter.instance).to have_received(:load).with("1", hash_including(foo: "bar", fizz: "buzz"))
      end

      it "respects per-adapter load options", :aggregate_failures do
        MultiJson.adapter.load_options = {foo: "bar"}
        expect(MultiJson.adapter.load_options).to eq({foo: "bar"})
        allow(MultiJson.adapter.instance).to receive(:load).and_call_original
        MultiJson.load("1", fizz: "buzz")
        expect(MultiJson.adapter.instance).to have_received(:load).with("1", hash_including(foo: "bar", fizz: "buzz"))
      end

      it "adapter-specific are overridden by global options", :aggregate_failures do
        MultiJson.load("1", fizz: "buzz")
        expect(MultiJson.adapter.load_options).to eq({foo: "foo"})
        expect(MultiJson.load_options).to eq({foo: "bar"})
        expect(MultiJson.adapter.instance).to have_received(:load).with("1", hash_including(foo: "bar", fizz: "buzz"))
      end
    end

    it "does not modify input" do
      input = %(\n\n  {"foo":"bar"} \n\n\t)
      expect do
        MultiJson.load(input)
      end.not_to(change { input })
    end

    it "does not modify input encoding" do
      input = "[123]"
      input.force_encoding("iso-8859-1")

      expect do
        MultiJson.load(input)
      end.not_to(change { input.encoding })
    end

    it "properly loads valid JSON" do
      expect(MultiJson.load('{"abc":"def"}')).to eq("abc" => "def")
    end

    it "returns nil on blank input" do
      [nil, "", " ", "\t\t\t", "\n", StringIO.new("")].each do |input|
        expect(MultiJson.load(input)).to be_nil
      end
    end

    examples = ['{"abc"}', "\x82\xAC\xEF"].tap do |arr|
      arr.pop if adapter.name.include?("Gson")
    end

    examples.each do |input|
      it "raises MultiJson::ParseError on invalid input: #{input.inspect}" do
        expect { MultiJson.load(input) }.to raise_error(MultiJson::ParseError)
      end
    end

    it "raises MultiJson::ParseError with data on invalid JSON", :aggregate_failures do
      data = "{invalid}"
      exception = get_exception(MultiJson::ParseError) { MultiJson.load data }
      expect(exception.data).to eq(data)
      expect(exception.cause).to match(adapter::ParseError)
    end

    it "catches MultiJson::DecodeError for legacy support", :aggregate_failures do
      data = "{invalid}"
      exception = get_exception(MultiJson::DecodeError) { MultiJson.load data }
      expect(exception.data).to eq(data)
      expect(exception.cause).to match(adapter::ParseError)
    end

    it "catches MultiJson::LoadError for legacy support", :aggregate_failures do
      data = "{invalid}"
      exception = get_exception(MultiJson::LoadError) { MultiJson.load data }
      expect(exception.data).to eq(data)
      expect(exception.cause).to match(adapter::ParseError)
    end

    it "stringifys symbol keys when encoding" do
      dumped_json = MultiJson.dump(a: 1, b: {c: 2})
      loaded_json = MultiJson.load(dumped_json)
      expect(loaded_json).to eq("a" => 1, "b" => {"c" => 2})
    end

    it "properly loads valid JSON in StringIOs" do
      json = StringIO.new('{"abc":"def"}')
      expect(MultiJson.load(json)).to eq("abc" => "def")
    end

    it "allows for symbolization of keys" do
      ex = [[ '{"abc":{"def":"hgi"}}', {abc: {def: "hgi"}} ],
            ['[{"abc":{"def":"hgi"}}]', [{abc: {def: "hgi"}}]],
            ['{"abc":[{"def":"hgi"}]}', {abc: [{def: "hgi"}]}]]
      ex.each { |json, expected| expect(MultiJson.load(json, symbolize_keys: true)).to eq(expected) }
    end

    it "allows to load JSON values" do
      expect(MultiJson.load("42")).to eq(42)
    end

    it "allows to load JSON with UTF-8 characters" do
      expect(MultiJson.load('{"color":"żółć"}')).to eq("color" => "żółć")
    end
  end
end
