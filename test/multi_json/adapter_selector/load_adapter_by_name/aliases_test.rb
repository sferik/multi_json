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
    skip "jrjackson gem is available on JRuby so no LoadError is raised" if java?
    error = assert_raises(LoadError) { @instance.send(:load_adapter_by_name, "jrjackson") }

    refute_includes(
      error.message, "adapters/jrjackson",
      "Should normalize 'jrjackson' to 'jr_jackson' for the file path"
    )
    # The LoadError comes from jr_jackson.rb's ``require "jrjackson"`` at
    # the top of the file — which means load_adapter_by_name got far
    # enough to load adapters/jr_jackson.rb, not adapters/jrjackson.
    assert_match(/jrjackson/, error.message)
  end
end
