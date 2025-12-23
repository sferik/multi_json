module AdapterDumpTests
  def test_dump_writes_decodable_json
    examples = [{"abc" => "def"}, [], 1, "2", true, false]

    examples.each do |e|
      assert_equal e, MultiJson.load(MultiJson.dump(e))
    end
    # nil case handled separately for assert_nil
    assert_nil MultiJson.load(MultiJson.dump(nil))
  end

  def test_dump_time_in_correct_format
    time = Time.at(1_355_218_745).utc
    dumped_json = MultiJson.dump(time)
    expected = "2012-12-11 09:39:05 UTC"

    assert_equal expected, MultiJson.load(dumped_json)
  end

  def test_dump_symbol_and_fixnum_keys_as_strings
    examples = [
      [{foo: {bar: "baz"}}, {"foo" => {"bar" => "baz"}}],
      [[{foo: {bar: "baz"}}], [{"foo" => {"bar" => "baz"}}]],
      [{foo: [{bar: "baz"}]}, {"foo" => [{"bar" => "baz"}]}],
      [{1 => {2 => {3 => "bar"}}}, {"1" => {"2" => {"3" => "bar"}}}]
    ]

    examples.each do |input, expected|
      assert_equal expected, MultiJson.load(MultiJson.dump(input))
    end
  end

  def test_dump_rootless_json
    assert_equal '"random rootless string"', MultiJson.dump("random rootless string")
    assert_equal "123", MultiJson.dump(123)
  end

  def test_dump_custom_objects_with_to_json
    skip "not supported" if adapter_class.name == "MultiJson::Adapters::Gson"
    klass = Class.new { def to_json(*) = '"foobar"' }

    assert_equal '"foobar"', MultiJson.dump(klass.new)
  end

  def test_dump_json_values
    assert_equal "42", MultiJson.dump(42)
  end

  def test_dump_json_with_utf8
    assert_equal '{"color":"żółć"}', MultiJson.dump("color" => "żółć")
  end
end
