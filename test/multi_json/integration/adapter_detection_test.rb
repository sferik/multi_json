# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "adapter_selection_test"

class AdapterDetectionIntegrationTest < Minitest::Test
  cover "MultiJSON*"

  include IntegrationTestSetup

  def test_loaded_adapter_detects_oj
    skip unless defined?(::Oj)
    with_json_ext_parser_removed do
      undefine_constants(:FastJsonparser, :JrJackson) do
        adapter = MultiJSON::AdapterSelector.send(:loaded_adapter)

        assert_equal :oj, adapter
      end
    end
  end

  def test_loaded_adapter_detects_yajl
    skip unless defined?(::Yajl)
    with_json_ext_parser_removed do
      undefine_constants(:FastJsonparser, :Oj, :JrJackson) do
        adapter = MultiJSON::AdapterSelector.send(:loaded_adapter)

        assert_equal :yajl, adapter
      end
    end
  end

  def test_loaded_adapter_detects_json_gem
    skip unless defined?(::JSON::Ext::Parser)
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      adapter = MultiJSON::AdapterSelector.send(:loaded_adapter)

      assert_equal :json_gem, adapter
    end
  end

  def test_loaded_adapter_detects_jr_jackson
    with_json_ext_parser_removed do
      undefine_constants(:FastJsonparser, :Oj, :Yajl) do
        with_temporary_constant(:JrJackson) do
          adapter = MultiJSON::AdapterSelector.send(:loaded_adapter)

          assert_equal :jr_jackson, adapter
        end
      end
    end
  end

  def test_loaded_adapter_detects_gson
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      with_json_ext_parser_removed do
        with_temporary_constant(:Gson) do
          adapter = MultiJSON::AdapterSelector.send(:loaded_adapter)

          assert_equal :gson, adapter
        end
      end
    end
  end

  private

  def with_temporary_constant(name)
    Object.const_set(name, Module.new)
    yield
  ensure
    Object.send(:remove_const, name) if Object.const_defined?(name)
  end

  def with_json_ext_parser_removed
    json_ext_parser = defined?(::JSON::Ext::Parser) ? ::JSON::Ext::Parser : nil
    JSON::Ext.send(:remove_const, :Parser) if json_ext_parser
    yield
  ensure
    JSON::Ext.const_set(:Parser, json_ext_parser) if json_ext_parser && !defined?(::JSON::Ext::Parser)
  end
end

if TestHelpers.jrjackson?
  class JrJacksonAliasIntegrationTest < Minitest::Test
    def test_allows_jrjackson_alias_as_symbol
      MultiJSON.use :jrjackson

      assert_equal MultiJSON::Adapters::JrJackson, MultiJSON.adapter
    end

    def test_allows_jrjackson_alias_as_string
      MultiJSON.use "jrjackson"

      assert_equal MultiJSON::Adapters::JrJackson, MultiJSON.adapter
    end
  end
end
