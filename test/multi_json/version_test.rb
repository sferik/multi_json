require_relative "../test_helper"

class VersionTest < Minitest::Test
  cover "MultiJson::Version*"

  def test_major_version_is_defined
    assert_kind_of Integer, MultiJson::Version::MAJOR
  end

  def test_minor_version_is_defined
    assert_kind_of Integer, MultiJson::Version::MINOR
  end

  def test_patch_version_is_defined
    assert_kind_of Integer, MultiJson::Version::PATCH
  end

  def test_pre_version_is_nil
    assert_nil MultiJson::Version::PRE
  end

  def test_to_s_returns_dotted_version_string
    expected = "#{MultiJson::Version::MAJOR}.#{MultiJson::Version::MINOR}.#{MultiJson::Version::PATCH}"

    assert_equal expected, MultiJson::Version.to_s
  end

  def test_to_s_includes_major_version
    assert MultiJson::Version.to_s.start_with?("#{MultiJson::Version::MAJOR}.")
  end

  def test_to_s_includes_minor_version
    assert_includes MultiJson::Version.to_s, ".#{MultiJson::Version::MINOR}."
  end

  def test_to_s_includes_patch_version
    assert MultiJson::Version.to_s.end_with?(".#{MultiJson::Version::PATCH}")
  end

  def test_to_s_uses_dot_as_separator
    assert_equal 2, MultiJson::Version.to_s.count(".")
  end

  def test_version_constant_is_frozen_string
    assert_predicate MultiJson::VERSION, :frozen?
    assert_equal MultiJson::Version.to_s, MultiJson::VERSION
  end

  def test_to_s_includes_pre_version_when_set
    with_pre_version("beta1") do
      expected = "#{MultiJson::Version::MAJOR}.#{MultiJson::Version::MINOR}.#{MultiJson::Version::PATCH}.beta1"

      assert_equal expected, MultiJson::Version.to_s
    end
  end

  def test_to_s_excludes_nil_pre_from_version
    # PRE is currently nil, so version should have 2 dots (3 components)
    assert_equal 2, MultiJson::Version.to_s.count(".")
    refute_match(/\.nil/, MultiJson::Version.to_s)
  end

  def test_pre_version_appears_at_end_of_version_string
    with_pre_version("alpha") do
      assert_match(/\.alpha$/, MultiJson::Version.to_s)
    end
  end

  def test_to_s_with_pre_has_three_dots
    with_pre_version("rc1") do
      assert_equal 3, MultiJson::Version.to_s.count(".")
    end
  end

  private

  def with_pre_version(pre_value)
    original_pre = MultiJson::Version::PRE
    silence_warnings { MultiJson::Version.const_set(:PRE, pre_value) }
    yield
  ensure
    silence_warnings { MultiJson::Version.const_set(:PRE, original_pre) }
  end
end
