require_relative "../../test_helper"
require "multi_json/adapter_selector"

class InstallableAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_installable_adapter_tries_requirement_map
    result = MultiJson.send(:installable_adapter)

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_installable_adapter_returns_nil_when_none_installable
    break_requirements do
      result = MultiJson.send(:installable_adapter)

      assert_nil result
    end
  end

  def test_installable_adapter_requires_library
    result = MultiJson.send(:installable_adapter)

    refute_nil result
  end
end

class InstallableAdapterRequirementMapTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_installable_adapter_uses_multijson_requirement_map
    result = MultiJson.send(:installable_adapter)

    refute_nil result
    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_installable_adapter_iterates_requirement_map
    result = MultiJson.send(:installable_adapter)

    refute_nil result
    assert_includes MultiJson::REQUIREMENT_MAP.keys, result
  end
end
