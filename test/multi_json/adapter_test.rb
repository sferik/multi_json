require_relative "../test_helper"

class AdapterInheritanceTest < Minitest::Test
  cover "MultiJson::Adapter*"

  def test_inherited_copies_default_load_options
    parent = Class.new(MultiJson::Adapter) do
      defaults :load, {symbolize_keys: true}
    end

    child = Class.new(parent)

    assert_equal({symbolize_keys: true}, child.default_load_options)
  end

  def test_inherited_copies_default_dump_options
    parent = Class.new(MultiJson::Adapter) do
      defaults :dump, {pretty: true}
    end

    child = Class.new(parent)

    assert_equal({pretty: true}, child.default_dump_options)
  end

  def test_inherited_without_default_options
    parent = Class.new(MultiJson::Adapter)
    child = Class.new(parent)

    assert_empty(child.default_load_options)
    assert_empty(child.default_dump_options)
  end
end
