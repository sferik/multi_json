# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for module-level reset behavior
class OptionsCacheModuleTest < Minitest::Test
  cover "MultiJSON::OptionsCache*"

  def setup
    MultiJSON::OptionsCache.reset
  end

  def test_module_reset_creates_new_stores
    old_dump = MultiJSON::OptionsCache.dump
    old_load = MultiJSON::OptionsCache.load

    MultiJSON::OptionsCache.reset

    refute_same old_dump, MultiJSON::OptionsCache.dump
    refute_same old_load, MultiJSON::OptionsCache.load
  end

  def test_module_dump_returns_store
    assert_kind_of MultiJSON::OptionsCache::Store, MultiJSON::OptionsCache.dump
  end

  def test_module_load_returns_store
    assert_kind_of MultiJSON::OptionsCache::Store, MultiJSON::OptionsCache.load
  end

  def test_module_reset_creates_dump_store
    MultiJSON::OptionsCache.reset

    assert_kind_of MultiJSON::OptionsCache::Store, MultiJSON::OptionsCache.dump
  end

  def test_module_reset_creates_load_store
    MultiJSON::OptionsCache.reset

    assert_kind_of MultiJSON::OptionsCache::Store, MultiJSON::OptionsCache.load
  end
end
