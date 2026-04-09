# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

# Tests for cache reset behavior
class OptionsCacheResetTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_load_options_setter_resets_cache_before_assignment
    reset_called = track_cache_reset { @test_class.load_options = {test: true} }

    assert reset_called
  end

  def test_dump_options_setter_resets_cache_before_assignment
    reset_called = track_cache_reset { @test_class.dump_options = {test: true} }

    assert reset_called
  end

  def test_load_options_stores_value_in_instance_variable
    @test_class.load_options = {stored: "value"}

    assert_equal({stored: "value"}, @test_class.instance_variable_get(:@load_options))
  end

  def test_dump_options_stores_value_in_instance_variable
    @test_class.dump_options = {stored: "value"}

    assert_equal({stored: "value"}, @test_class.instance_variable_get(:@dump_options))
  end

  private

  def track_cache_reset
    reset_called = false
    original_reset = MultiJson::OptionsCache.method(:reset)

    silence_warnings do
      MultiJson::OptionsCache.define_singleton_method(:reset) { reset_called = original_reset.call }
    end

    yield
    reset_called
  ensure
    silence_warnings { MultiJson::OptionsCache.define_singleton_method(:reset, original_reset) }
  end
end
