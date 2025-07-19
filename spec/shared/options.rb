shared_examples_for "has options" do |object|
  subject { object.respond_to?(:call) ? object.call : object }

  describe "dump options" do
    before do
      subject.dump_options = nil
    end

    after do
      subject.dump_options = nil
    end

    it "returns default options if not set" do
      expect(subject.dump_options).to eq(subject.default_dump_options)
    end

    it "returns frozen default options" do
      expect(subject.default_dump_options).to be_frozen
    end

    it "allows hashes" do
      subject.dump_options = {foo: "bar"}
      expect(subject.dump_options).to eq(foo: "bar")
    end

    it "allows objects that implement #to_hash" do
      value = Object.new
      allow(value).to receive(:to_hash).and_return(foo: "bar")
      subject.dump_options = value
      expect(subject.dump_options).to eq(foo: "bar")
    end

    it "evaluates lambda returning options (with args)" do
      subject.dump_options = ->(a1, a2) { {a1 => a2} }
      expect(subject.dump_options("1", "2")).to eq("1" => "2")
    end

    it "evaluates lambda returning options (with no args)" do
      subject.dump_options = -> { {foo: "bar"} }
      expect(subject.dump_options).to eq(foo: "bar")
    end

    it "returns empty hash in all other cases" do
      [true, false, 10, nil].each do |val|
        subject.dump_options = val
        expect(subject.dump_options).to eq(subject.default_dump_options)
      end
    end
  end

  describe "load options" do
    before do
      subject.load_options = nil
    end

    after do
      subject.load_options = nil
    end

    it "returns default options if not set" do
      expect(subject.load_options).to eq(subject.default_load_options)
    end

    it "returns frozen default options" do
      expect(subject.default_load_options).to be_frozen
    end

    it "allows hashes" do
      subject.load_options = {foo: "bar"}
      expect(subject.load_options).to eq(foo: "bar")
    end

    it "allows objects that implement #to_hash" do
      value = Object.new
      allow(value).to receive(:to_hash).and_return(foo: "bar")
      subject.load_options = value
      expect(subject.load_options).to eq(foo: "bar")
    end

    it "evaluates lambda returning options (with args)" do
      subject.load_options = ->(a1, a2) { {a1 => a2} }
      expect(subject.load_options("1", "2")).to eq("1" => "2")
    end

    it "evaluates lambda returning options (with no args)" do
      subject.load_options = -> { {foo: "bar"} }
      expect(subject.load_options).to eq(foo: "bar")
    end

    it "returns empty hash in all other cases" do
      [true, false, 10, nil].each do |val|
        subject.load_options = val
        expect(subject.load_options).to eq(subject.default_load_options)
      end
    end
  end
end
