# frozen_string_literal: true

module JsonCommonAdapterTests
  def test_dump_with_pretty_option_passes_default_pretty_options
    MultiJson.dump_options = MultiJson.adapter.dump_options = nil
    object = "foo"
    expected_options = {indent: "  ", space: " ", object_nl: "\n", array_nl: "\n"}

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :pretty_generate, capture, call_original: true) do
      MultiJson.dump(object, pretty: true)
    end

    assert_equal object, called_with[0]
    assert_equal expected_options, called_with[1]
  end

  def test_dump_retains_pretty_formatting_when_cached
    MultiJson.dump_options = MultiJson.adapter.dump_options = nil
    object = {foo: "bar"}
    pretty_output = JSON.pretty_generate(object)

    outputs = 2.times.map { MultiJson.dump(object, pretty: true) }

    assert(outputs.all? { |o| o == pretty_output })
  end

  def test_dump_with_indent_option
    MultiJson.dump_options = MultiJson.adapter.dump_options = nil
    object = "foo"

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :generate, capture, call_original: true) do
      MultiJson.dump(object, indent: "\t")
    end

    assert_equal object, called_with[0]
    assert_equal({indent: "\t"}, called_with[1])
  end
end
