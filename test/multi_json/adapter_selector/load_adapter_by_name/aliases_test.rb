# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests that load_adapter_by_name normalizes "jrjackson" to "jr_jackson"
# (the JrJackson gem name differs from the adapter file/class name).
class JrJacksonAliasTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def test_load_adapter_by_name_normalizes_jrjackson_to_jr_jackson
    captured_path = nil
    spy = path_capturing_module(->(path) { captured_path = path })
    instance = Object.new.extend(spy)
    assert_raises(::LoadError) { instance.send(:load_adapter_by_name, "jrjackson") }

    assert_equal "adapters/jr_jackson", captured_path
  end

  private

  def path_capturing_module(callback)
    ::Module.new do
      include MultiJson::AdapterSelector

      define_method(:require_relative) do |path|
        callback.call(path)
        raise ::LoadError, "stubbed - #{path}"
      end
    end
  end
end
