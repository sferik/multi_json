# frozen_string_literal: true

require "stringio"
require_relative "options_tests"
require_relative "adapter_dump_tests"
require_relative "adapter_load_tests"

module AdapterTests
  def self.included(base)
    base.include OptionsTests
    base.include AdapterDumpTests
    base.include AdapterLoadTests
  end

  def setup
    MultiJSON.use adapter_class
  end

  def subject
    adapter_class
  end

  def test_does_not_modify_argument_hashes_when_loading
    options = {symbolize_names: true, adapter: :json_gem}
    original = options.dup
    MultiJSON.load("{}", options)

    assert_equal original, options
  end

  def test_does_not_modify_argument_hashes_when_dumping
    options = {pretty: false, adapter: :json_gem}
    original = options.dup
    MultiJSON.dump([42], options)

    assert_equal original, options
  end

  def test_dump_options_respected_globally
    with_default_options do
      MultiJSON.dump_options = {foo: "bar"}

      assert_equal({foo: "bar"}, MultiJSON.dump_options)
    end
  end

  def test_load_options_respected_globally
    with_default_options do
      MultiJSON.load_options = {foo: "bar"}

      assert_equal({foo: "bar"}, MultiJSON.load_options)
    end
  end
end
