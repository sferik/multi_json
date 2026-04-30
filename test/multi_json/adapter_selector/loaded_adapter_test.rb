# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/adapter_selector"

module LoadedAdapterTestHelpers
  def with_temporary_constant(name)
    was_defined = Object.const_defined?(name)
    Object.const_set(name, Module.new) unless was_defined
    yield
  ensure
    Object.send(:remove_const, name) unless was_defined
  end

  def with_json_ext_parser
    return yield if defined?(::JSON::Ext::Parser)

    Object.const_set(:JSON, Module.new) unless Object.const_defined?(:JSON)
    JSON.const_set(:Ext, Module.new) unless JSON.const_defined?(:Ext)
    JSON::Ext.const_set(:Parser, Class.new)
    yield
  ensure
    JSON::Ext.send(:remove_const, :Parser) if defined?(JSON::Ext::Parser)
  end

  def without_json_ext_parser
    return yield unless defined?(::JSON::Ext::Parser)

    parser = JSON::Ext::Parser
    JSON::Ext.send(:remove_const, :Parser)
    yield
  ensure
    JSON::Ext.const_set(:Parser, parser) if parser
  end
end

class LoadedAdapterTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"
  include LoadedAdapterTestHelpers

  def test_loaded_adapter_detects_fast_jsonparser
    skip unless defined?(::FastJsonparser)

    without_json_ext_parser do
      undefine_constants(:Oj, :Yajl, :JrJackson) do
        assert_equal :fast_jsonparser, MultiJSON.send(:loaded_adapter)
      end
    end
  end

  def test_loaded_adapter_detects_oj
    skip unless defined?(::Oj)

    without_json_ext_parser do
      undefine_constants(:FastJsonparser, :JrJackson) { assert_equal :oj, MultiJSON.send(:loaded_adapter) }
    end
  end

  def test_loaded_adapter_detects_yajl
    skip unless defined?(::Yajl)

    without_json_ext_parser do
      undefine_constants(:FastJsonparser, :Oj, :JrJackson) { assert_equal :yajl, MultiJSON.send(:loaded_adapter) }
    end
  end

  def test_loaded_adapter_returns_nil_when_none_loaded
    simulate_no_adapters { assert_nil MultiJSON.send(:loaded_adapter) }
  end

  def test_loaded_adapter_detects_jr_jackson_when_defined
    without_json_ext_parser do
      undefine_constants(:FastJsonparser, :Oj, :Yajl) do
        with_temporary_constant(:JrJackson) { assert_equal :jr_jackson, MultiJSON.send(:loaded_adapter) }
      end
    end
  end

  def test_loaded_adapter_detects_json_gem_when_defined
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      with_json_ext_parser { assert_equal :json_gem, MultiJSON.send(:loaded_adapter) }
    end
  end

  def test_loaded_adapter_detects_gson_when_defined
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      without_json_ext_parser do
        with_temporary_constant(:Gson) { assert_equal :gson, MultiJSON.send(:loaded_adapter) }
      end
    end
  end
end

class LoadedAdapterPriorityTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"
  include LoadedAdapterTestHelpers

  def test_json_gem_takes_priority_over_fast_jsonparser
    skip unless defined?(::FastJsonparser)

    undefine_constants(:JrJackson) do
      with_json_ext_parser { assert_equal :json_gem, MultiJSON.send(:loaded_adapter) }
    end
  end

  def test_fast_jsonparser_takes_priority_over_oj
    skip unless defined?(::FastJsonparser) && defined?(::Oj)

    without_json_ext_parser do
      undefine_constants(:JrJackson) { assert_equal :fast_jsonparser, MultiJSON.send(:loaded_adapter) }
    end
  end

  def test_oj_takes_priority_over_yajl
    skip unless defined?(::Oj) && defined?(::Yajl)

    without_json_ext_parser do
      undefine_constants(:FastJsonparser, :JrJackson) { assert_equal :oj, MultiJSON.send(:loaded_adapter) }
    end
  end

  def test_yajl_takes_priority_over_jr_jackson
    skip unless defined?(::Yajl)
    without_json_ext_parser do
      undefine_constants(:FastJsonparser, :Oj) do
        with_temporary_constant(:JrJackson) { assert_equal :yajl, MultiJSON.send(:loaded_adapter) }
      end
    end
  end

  def test_jr_jackson_takes_priority_over_gson
    without_json_ext_parser do
      undefine_constants(:FastJsonparser, :Oj, :Yajl) do
        with_temporary_constant(:JrJackson) do
          with_temporary_constant(:Gson) { assert_equal :jr_jackson, MultiJSON.send(:loaded_adapter) }
        end
      end
    end
  end
end

# Tests for loaded_adapter and installable_adapter methods
class AdapterDetectionEdgeCasesTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_loaded_adapter_returns_nil_when_none_defined
    simulate_no_adapters do
      result = MultiJSON.send(:loaded_adapter)

      assert_nil result
    end
  end

  def test_installable_adapter_iterates_requirement_map
    result = MultiJSON.send(:installable_adapter)

    refute_nil result
  end

  def test_installable_adapter_returns_nil_when_none_installable
    break_requirements do
      result = MultiJSON.send(:installable_adapter)

      assert_nil result
    end
  end
end
