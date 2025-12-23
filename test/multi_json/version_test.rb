require_relative "../test_helper"

class VersionTest < Minitest::Test
  cover "MultiJson::Version*"

  def test_major_version_is_defined
    assert_equal 1, MultiJson::Version::MAJOR
  end

  def test_minor_version_is_defined
    assert_equal 19, MultiJson::Version::MINOR
  end

  def test_patch_version_is_defined
    assert_equal 0, MultiJson::Version::PATCH
  end

  def test_pre_version_is_nil
    assert_nil MultiJson::Version::PRE
  end

  def test_to_s_returns_dotted_version_string
    assert_equal "1.19.0", MultiJson::Version.to_s
  end

  def test_to_s_includes_major_version
    assert_match(/^1\./, MultiJson::Version.to_s)
  end

  def test_to_s_includes_minor_version
    assert_match(/\.19\./, MultiJson::Version.to_s)
  end

  def test_to_s_includes_patch_version
    assert_match(/\.0$/, MultiJson::Version.to_s)
  end

  def test_to_s_uses_dot_as_separator
    assert_equal 2, MultiJson::Version.to_s.count(".")
  end

  def test_version_constant_is_frozen_string
    assert_predicate MultiJson::VERSION, :frozen?
    assert_equal "1.19.0", MultiJson::VERSION
  end
end
