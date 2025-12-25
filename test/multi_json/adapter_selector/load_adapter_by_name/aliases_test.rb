require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class AliasesTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_aliases_contains_jrjackson
    assert MultiJson::AdapterSelector::ALIASES.key?("jrjackson")
  end

  def test_aliases_maps_jrjackson_to_jr_jackson
    assert_equal "jr_jackson", MultiJson::AdapterSelector::ALIASES["jrjackson"]
  end

  def test_aliases_is_frozen
    assert_predicate MultiJson::AdapterSelector::ALIASES, :frozen?
  end
end

# Tests that ALIASES.fetch uses the correct key
class AliasesFetchBehaviorTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def test_load_adapter_by_name_uses_alias_key_not_nil
    skip "jrjackson gem is available on JRuby so no LoadError is raised" if java?
    error = assert_raises(LoadError) { @instance.send(:load_adapter_by_name, "jrjackson") }

    refute_includes(
      error.message, "adapters/jrjackson",
      "Should use alias 'jr_jackson' not original 'jrjackson' for file path"
    )
  end
end
