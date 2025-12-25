require_relative "../../../test_helper"

class DeprecatedMethodsTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.default_options = {foo: "bar"} }
    end

    assert warned
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.default_options }
    end

    assert warned
  end

  def test_cached_options_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.cached_options }
    end

    assert warned
  end

  def test_reset_cached_options_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.reset_cached_options! }
    end

    assert warned
  end

  def test_default_options_setter_sets_load_options
    silence_warnings { MultiJson.default_options = {test: "value"} }

    assert_equal({test: "value"}, MultiJson.load_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_sets_dump_options
    silence_warnings { MultiJson.default_options = {test: "value"} }

    assert_equal({test: "value"}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_returns_load_options
    MultiJson.load_options = {specific: "value"}

    result = silence_warnings { MultiJson.default_options }

    assert_equal({specific: "value"}, result)
  ensure
    MultiJson.load_options = nil
  end
end
