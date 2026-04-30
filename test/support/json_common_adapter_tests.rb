# frozen_string_literal: true

module JsonCommonAdapterTests
  def test_dump_with_pretty_option_passes_default_pretty_options
    MultiJSON.generate_options = MultiJSON.adapter.generate_options = nil
    object = "foo"
    expected_options = {indent: "  ", space: " ", object_nl: "\n", array_nl: "\n"}

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :pretty_generate, capture, call_original: true) do
      MultiJSON.generate(object, pretty: true)
    end

    assert_equal object, called_with[0]
    assert_equal expected_options, called_with[1]
  end

  def test_dump_retains_pretty_formatting_when_cached
    MultiJSON.generate_options = MultiJSON.adapter.generate_options = nil
    object = {foo: "bar"}
    pretty_output = JSON.pretty_generate(object)

    outputs = 2.times.map { MultiJSON.generate(object, pretty: true) }

    assert(outputs.all? { |o| o == pretty_output })
  end

  def test_dump_with_indent_option
    MultiJSON.generate_options = MultiJSON.adapter.generate_options = nil
    object = "foo"

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :generate, capture, call_original: true) do
      MultiJSON.generate(object, indent: "\t")
    end

    assert_equal object, called_with[0]
    assert_equal({indent: "\t"}, called_with[1])
  end

  def test_dump_with_pretty_and_extra_option_merges_prototype_with_override
    MultiJSON.generate_options = MultiJSON.adapter.generate_options = nil
    object = {foo: "bar"}

    called_with = nil
    capture = ->(obj, opts = {}) { called_with = [obj, opts] }

    with_stub(JSON, :pretty_generate, capture, call_original: true) do
      MultiJSON.generate(object, pretty: true, indent: "\t")
    end

    assert_equal object, called_with[0]
    # The :pretty key is stripped; the override (:indent) wins over the prototype default.
    assert_equal "\t", called_with[1][:indent]
  end
end
