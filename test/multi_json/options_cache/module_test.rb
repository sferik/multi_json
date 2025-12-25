require_relative "../../test_helper"

# Tests for module-level reset behavior
class OptionsCacheModuleTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_module_reset_creates_new_stores
    old_dump = MultiJson::OptionsCache.dump
    old_load = MultiJson::OptionsCache.load

    MultiJson::OptionsCache.reset

    refute_same old_dump, MultiJson::OptionsCache.dump
    refute_same old_load, MultiJson::OptionsCache.load
  end

  def test_module_dump_returns_store
    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.dump
  end

  def test_module_load_returns_store
    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.load
  end

  def test_module_reset_creates_dump_store
    MultiJson::OptionsCache.reset

    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.dump
  end

  def test_module_reset_creates_load_store
    MultiJson::OptionsCache.reset

    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.load
  end
end
