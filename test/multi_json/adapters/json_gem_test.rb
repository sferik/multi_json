# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/adapter_tests"
require_relative "../../support/json_common_adapter_tests"
require "multi_json/adapters/json_gem"
require "open3"
require "rbconfig"
require "tempfile"

class JsonGemAdapterTest < Minitest::Test
  cover "MultiJSON::Adapters::JsonGem*"

  include AdapterTests
  include JsonCommonAdapterTests

  def adapter_class
    MultiJSON::Adapters::JsonGem
  end

  def test_dump_calls_as_json_on_objects
    klass = Class.new do
      attr_accessor :as_json_called

      def as_json(*)
        @as_json_called = true
        {abc: "def"}
      end
    end

    object = klass.new
    MultiJSON.dump(object)

    assert object.as_json_called
  end

  def test_dump_calls_as_json_with_pretty_option
    klass = Class.new do
      attr_accessor :as_json_called

      def as_json(*)
        @as_json_called = true
        {abc: "def"}
      end
    end

    object = klass.new
    MultiJSON.dump(object, pretty: true)

    assert object.as_json_called
  end

  def test_load_raises_parse_error_on_invalid_utf8
    # 0xFF is not a valid UTF-8 byte sequence
    invalid = (+"\xFF").force_encoding(Encoding::ASCII_8BIT)

    assert_raises(MultiJSON::ParseError) do
      MultiJSON.load(invalid, adapter: :json_gem)
    end
  end

  def test_load_handles_ascii_8bit_tagged_utf8
    # Ruby HTTP clients return response bodies tagged as ASCII-8BIT
    # even when the bytes are valid UTF-8 (GH-64)
    json = (+"{\"name\":\"Fran\xC3\xA7ois\"}").force_encoding(Encoding::ASCII_8BIT)

    result = MultiJSON::Adapters::JsonGem.load(json)

    assert_equal({"name" => "François"}, result)
  end

  def test_load_does_not_mutate_cached_options
    MultiJSON.use :json_gem
    MultiJSON.parse_options = nil
    MultiJSON::OptionsCache.reset

    MultiJSON.parse('{"a":1}', symbolize_names: true)
    MultiJSON.parse('{"a":1}', symbolize_names: true)

    cached = MultiJSON::OptionsCache.load.send(:instance_variable_get, :@cache).values.first

    assert_includes cached.keys, :symbolize_names,
      "expected cached load options to retain :symbolize_names key"
  end

  private

  def run_script(script_content)
    Tempfile.create(["multi_json_json_gem", ".rb"]) do |file|
      file.write(script_content)
      file.flush
      file.close

      Open3.capture2(RbConfig.ruby, file.path)
    end
  end

  def activesupport_script(code)
    <<~RUBY
      $LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
      require "multi_json"
      require "multi_json/adapters/json_gem"
      require "active_support/json"

      #{code}
    RUBY
  end
end

class JsonGemWithActiveSupportTest < Minitest::Test
  cover "MultiJSON::Adapters::JsonGem*"

  def setup
    MultiJSON.use MultiJSON::Adapters::JsonGem
  end

  def test_prettifies_output_when_pretty_is_true
    script = activesupport_script("puts MultiJSON.generate({a: 1, b: 2, c: {d: {f: 2}}}, pretty: true, adapter: :json_gem)")
    output, status = run_script(script)

    expected = JSON.pretty_generate({a: 1, b: 2, c: {d: {f: 2}}})

    assert_predicate status, :success?
    assert_equal "#{expected}\n", output
  end

  def test_serializes_objects_that_define_to_hash
    script = activesupport_script('Class.new { def to_hash = {abc: "def"} }.then { puts MultiJSON.generate(_1.new, adapter: :json_gem) }')
    output, status = run_script(script)

    assert_predicate status, :success?
    assert_equal "{\"abc\":\"def\"}\n", output
  end

  def test_serializes_time_using_activesupport_format
    script = activesupport_script("puts MultiJSON.generate(Time.utc(2025, 12, 4, 13, 39, 46, 705000), adapter: :json_gem)")
    output, status = run_script(script)

    assert_predicate status, :success?
    assert_includes output, "2025-12-04T13:39:46.705Z"
  end

  private

  def run_script(script_content)
    Tempfile.create(["multi_json_json_gem", ".rb"]) do |file|
      file.write(script_content)
      file.flush
      file.close

      Open3.capture2(RbConfig.ruby, file.path)
    end
  end

  def activesupport_script(code)
    <<~RUBY
      $LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)
      require "multi_json"
      require "multi_json/adapters/json_gem"
      require "active_support/json"

      #{code}
    RUBY
  end
end
