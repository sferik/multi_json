# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

# Tests for cache reset behavior
class OptionsCacheResetTest < Minitest::Test
  cover "MultiJSON::Options*"

  def setup
    @test_class = Class.new { extend MultiJSON::Options }
  end

  def teardown
    @test_class.parse_options = nil
    @test_class.generate_options = nil
  end

  def test_parse_options_setter_resets_cache_before_assignment
    reset_called = track_cache_reset { @test_class.parse_options = {test: true} }

    assert reset_called
  end

  def test_generate_options_setter_resets_cache_before_assignment
    reset_called = track_cache_reset { @test_class.generate_options = {test: true} }

    assert reset_called
  end

  def test_parse_options_stores_value_in_instance_variable
    @test_class.parse_options = {stored: "value"}

    assert_equal({stored: "value"}, @test_class.instance_variable_get(:@parse_options))
  end

  def test_generate_options_stores_value_in_instance_variable
    @test_class.generate_options = {stored: "value"}

    assert_equal({stored: "value"}, @test_class.instance_variable_get(:@generate_options))
  end

  private

  def track_cache_reset
    reset_called = false
    original_reset = MultiJSON::OptionsCache.method(:reset)

    silence_warnings do
      MultiJSON::OptionsCache.define_singleton_method(:reset) { reset_called = original_reset.call }
    end

    yield
    reset_called
  ensure
    silence_warnings { MultiJSON::OptionsCache.define_singleton_method(:reset, original_reset) }
  end
end
