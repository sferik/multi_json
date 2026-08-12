# frozen_string_literal: true

module AdapterDumpTests
  def test_dump_writes_decodable_json
    examples = [{"abc" => "def"}, [], 1, "2", true, false]

    examples.each do |e|
      assert_equal e, MultiJSON.load(MultiJSON.dump(e))
    end
    # nil case handled separately for assert_nil
    assert_nil MultiJSON.load(MultiJSON.dump(nil))
  end

  def test_dump_time_in_correct_format
    time = Time.at(1_355_218_745).utc
    dumped_json = MultiJSON.dump(time)
    expected = "2012-12-11 09:39:05 UTC"

    assert_equal expected, MultiJSON.load(dumped_json)
  end

  def test_dump_symbol_and_fixnum_keys_as_strings
    examples = [
      [{foo: {bar: "baz"}}, {"foo" => {"bar" => "baz"}}],
      [[{foo: {bar: "baz"}}], [{"foo" => {"bar" => "baz"}}]],
      [{foo: [{bar: "baz"}]}, {"foo" => [{"bar" => "baz"}]}],
      [{1 => {2 => {3 => "bar"}}}, {"1" => {"2" => {"3" => "bar"}}}]
    ]

    examples.each do |input, expected|
      assert_equal expected, MultiJSON.load(MultiJSON.dump(input))
    end
  end

  def test_dump_rootless_json
    assert_equal '"random rootless string"', MultiJSON.dump("random rootless string")
    assert_equal "123", MultiJSON.dump(123)
  end

  def test_dump_custom_objects_with_to_json
    skip "not supported" if adapter_class.name == "MultiJSON::Adapters::Gson"
    klass = Class.new { def to_json(*) = '"foobar"' }

    assert_equal '"foobar"', MultiJSON.dump(klass.new)
  end

  def test_dump_json_values
    assert_equal "42", MultiJSON.dump(42)
  end

  def test_dump_json_with_utf8
    assert_equal '{"color":"żółć"}', MultiJSON.dump("color" => "żółć")
  end

  # Regression test for https://github.com/sferik/multi_json/issues/70,
  # where the json_gem and Oj adapters tested for the presence of the
  # :pretty key instead of its value and pretty-printed either way.
  def test_dump_with_falsy_pretty_option_is_compact
    with_default_options do
      assert_equal '{"abc":"def"}', MultiJSON.dump({"abc" => "def"}, pretty: false)
      assert_equal '{"abc":"def"}', MultiJSON.dump({"abc" => "def"}, pretty: nil)
    end
  end
end
