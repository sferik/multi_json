# frozen_string_literal: true

require "stringio"

module AdapterParseTests
  def test_load_does_not_modify_input
    input = %(\n\n  {"foo":"bar"} \n\n\t)
    original = input.dup
    MultiJSON.parse(input)

    assert_equal original, input
  end

  def test_load_does_not_modify_input_encoding
    input = +"[123]"
    input.force_encoding("iso-8859-1")
    original_encoding = input.encoding
    MultiJSON.parse(input)

    assert_equal original_encoding, input.encoding
  end

  def test_load_properly_loads_valid_json
    assert_equal({"abc" => "def"}, MultiJSON.parse('{"abc":"def"}'))
  end

  def test_load_returns_nil_on_blank_input
    [nil, "", " ", "\t\t\t", "\n", StringIO.new("")].each do |input|
      assert_nil MultiJSON.parse(input)
    end
  end

  def test_load_raises_parse_error_on_invalid_json
    invalid_inputs = ['{"abc"}']
    invalid_inputs << "\x82\xAC\xEF" unless adapter_class.name.include?("Gson")

    invalid_inputs.each do |input|
      assert_raises(MultiJSON::ParseError) { MultiJSON.parse(input) }
    end
  end

  def test_load_raises_parse_error_with_data
    data = "{invalid}"
    exception = get_exception(MultiJSON::ParseError) { MultiJSON.parse(data) }

    assert_equal data, exception.data
    assert_operator adapter_class::ParseError, :===, exception.cause,
      "Expected #{adapter_class}::ParseError === #{exception.cause.class}"
  end

  def test_load_stringifies_symbol_keys_when_encoding
    dumped_json = MultiJSON.generate({a: 1, b: {c: 2}})
    loaded_json = MultiJSON.parse(dumped_json)

    assert_equal({"a" => 1, "b" => {"c" => 2}}, loaded_json)
  end

  def test_load_properly_loads_json_from_stringio
    json = StringIO.new('{"abc":"def"}')

    assert_equal({"abc" => "def"}, MultiJSON.parse(json))
  end

  def test_load_allows_symbolization_of_keys
    examples = [
      ['{"abc":{"def":"hgi"}}', {abc: {def: "hgi"}}],
      ['[{"abc":{"def":"hgi"}}]', [{abc: {def: "hgi"}}]],
      ['{"abc":[{"def":"hgi"}]}', {abc: [{def: "hgi"}]}]
    ]

    examples.each do |json, expected|
      assert_equal expected, MultiJSON.parse(json, symbolize_names: true)
    end
  end

  def test_load_json_values
    assert_equal 42, MultiJSON.parse("42")
  end

  def test_load_json_with_utf8
    assert_equal({"color" => "żółć"}, MultiJSON.parse('{"color":"żółć"}'))
  end
end
