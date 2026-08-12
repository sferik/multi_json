# frozen_string_literal: true

module JsonCommonAdapterTests
  def test_dump_with_pretty_option_passes_default_pretty_options
    MultiJSON.dump_options = MultiJSON.adapter.dump_options = nil
    object = "foo"
    expected_options = {indent: "  ", space: " ", object_nl: "\n", array_nl: "\n"}

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :pretty_generate, capture, call_original: true) do
      MultiJSON.dump(object, pretty: true)
    end

    assert_equal object, called_with[0]
    assert_equal expected_options, called_with[1]
  end

  def test_dump_retains_pretty_formatting_when_cached
    MultiJSON.dump_options = MultiJSON.adapter.dump_options = nil
    object = {foo: "bar"}
    pretty_output = JSON.pretty_generate(object)

    outputs = 2.times.map { MultiJSON.dump(object, pretty: true) }

    assert(outputs.all? { |o| o == pretty_output })
  end

  # Regression test for https://github.com/sferik/multi_json/issues/70.
  # A falsy :pretty must reach neither generator as an option: the JSON
  # gem doesn't understand it, and json 3.x raises on unknown keywords.
  def test_dump_with_falsy_pretty_option_uses_plain_generator
    MultiJSON.dump_options = MultiJSON.adapter.dump_options = nil
    object = "foo"

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :generate, capture, call_original: true) do
      MultiJSON.dump(object, pretty: false, indent: "\t")
    end

    assert_equal object, called_with[0]
    assert_equal({indent: "\t"}, called_with[1])
  end

  def test_dump_with_indent_option
    MultiJSON.dump_options = MultiJSON.adapter.dump_options = nil
    object = "foo"

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :generate, capture, call_original: true) do
      MultiJSON.dump(object, indent: "\t")
    end

    assert_equal object, called_with[0]
    assert_equal({indent: "\t"}, called_with[1])
  end
end
