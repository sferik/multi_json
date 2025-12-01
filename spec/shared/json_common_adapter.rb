shared_examples_for "JSON-like adapter" do |adapter|
  before { MultiJson.use adapter }

  describe ".dump" do
    before { MultiJson.dump_options = MultiJson.adapter.dump_options = nil }

    describe "with :pretty option set to true" do
      it "passes default pretty options" do
        object = "foo"
        options = {indent: "  ", space: " ", object_nl: "\n", array_nl: "\n"}
        allow(JSON).to receive(:pretty_generate).and_call_original
        MultiJson.dump(object, pretty: true)
        expect(JSON).to have_received(:pretty_generate).with(object, options)
      end

      it "retains pretty formatting when options are cached" do
        object = {foo: "bar"}
        pretty_output = JSON.pretty_generate(object)

        outputs = 2.times.map { MultiJson.dump(object, pretty: true) }

        expect(outputs).to all(eq(pretty_output))
      end
    end

    describe "with :indent option" do
      it "passes it on dump" do
        object = "foo"
        allow(JSON).to receive(:generate).and_call_original
        MultiJson.dump(object, indent: "\t")
        expect(JSON).to have_received(:generate).with(object, {indent: "\t"})
      end
    end
  end
end
