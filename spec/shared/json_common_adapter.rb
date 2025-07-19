shared_examples_for "JSON-like adapter" do |adapter|
  before { MultiJson.use adapter }

  describe ".dump" do
    before { MultiJson.dump_options = MultiJson.adapter.dump_options = nil }

    describe "with :pretty option set to true" do
      it "passes default pretty options" do
        object = "foo"
        options = {indent: "  ", space: " ", object_nl: "\n", array_nl: "\n"}
        expect(JSON).to receive(:generate).with(object, options).and_call_original
        MultiJson.dump(object, pretty: true)
      end
    end

    describe "with :indent option" do
      it "passes it on dump" do
        object = "foo"
        expect(JSON).to receive(:generate).with(object, {indent: "\t"}).and_call_original
        MultiJson.dump(object, indent: "\t")
      end
    end
  end
end
