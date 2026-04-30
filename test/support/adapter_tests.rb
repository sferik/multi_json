# frozen_string_literal: true

require "stringio"
require_relative "options_tests"
require_relative "adapter_generate_tests"
require_relative "adapter_parse_tests"

module AdapterTests
  def self.included(base)
    base.include OptionsTests
    base.include AdapterGenerateTests
    base.include AdapterParseTests
  end

  def setup
    MultiJSON.use adapter_class
  end

  def subject
    adapter_class
  end

  def test_does_not_modify_argument_hashes_when_loading
    options = {symbolize_names: true, pretty: false, adapter: :json_gem}
    original = options.dup
    MultiJSON.parse("{}", **options)

    assert_equal original, options
  end

  def test_does_not_modify_argument_hashes_when_dumping
    options = {symbolize_names: true, pretty: false, adapter: :json_gem}
    original = options.dup
    MultiJSON.generate([42], **options)

    assert_equal original, options
  end

  def test_dump_options_respected_globally
    with_default_options do
      MultiJSON.generate_options = {foo: "bar"}

      assert_equal({foo: "bar"}, MultiJSON.generate_options)
    end
  end

  def test_load_options_respected_globally
    with_default_options do
      MultiJSON.parse_options = {foo: "bar"}

      assert_equal({foo: "bar"}, MultiJSON.parse_options)
    end
  end
end
