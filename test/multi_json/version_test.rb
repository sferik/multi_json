# frozen_string_literal: true

require_relative "../test_helper"

class VersionTest < Minitest::Test
  cover "MultiJSON::Version*"

  def test_major_version_is_defined
    assert_kind_of Integer, MultiJSON::Version::MAJOR
  end

  def test_minor_version_is_defined
    assert_kind_of Integer, MultiJSON::Version::MINOR
  end

  def test_patch_version_is_defined
    assert_kind_of Integer, MultiJSON::Version::PATCH
  end

  def test_pre_version_is_nil
    assert_nil MultiJSON::Version::PRE
  end

  def test_to_s_returns_dotted_version_string
    expected = "#{MultiJSON::Version::MAJOR}.#{MultiJSON::Version::MINOR}.#{MultiJSON::Version::PATCH}"

    assert_equal expected, MultiJSON::Version.to_s
  end

  def test_to_s_includes_major_version
    assert MultiJSON::Version.to_s.start_with?("#{MultiJSON::Version::MAJOR}.")
  end

  def test_to_s_includes_minor_version
    assert_includes MultiJSON::Version.to_s, ".#{MultiJSON::Version::MINOR}."
  end

  def test_to_s_includes_patch_version
    assert MultiJSON::Version.to_s.end_with?(".#{MultiJSON::Version::PATCH}")
  end

  def test_to_s_uses_dot_as_separator
    assert_equal 2, MultiJSON::Version.to_s.count(".")
  end

  def test_version_constant_is_frozen_string
    assert_predicate MultiJSON::VERSION, :frozen?
    assert_equal MultiJSON::Version.to_s, MultiJSON::VERSION
  end

  def test_to_s_includes_pre_version_when_set
    with_pre_version("beta1") do
      expected = "#{MultiJSON::Version::MAJOR}.#{MultiJSON::Version::MINOR}.#{MultiJSON::Version::PATCH}.beta1"

      assert_equal expected, MultiJSON::Version.to_s
    end
  end

  def test_to_s_excludes_nil_pre_from_version
    # PRE is currently nil, so version should have 2 dots (3 components)
    assert_equal 2, MultiJSON::Version.to_s.count(".")
    refute_match(/\.nil/, MultiJSON::Version.to_s)
  end

  def test_pre_version_appears_at_end_of_version_string
    with_pre_version("alpha") do
      assert_match(/\.alpha$/, MultiJSON::Version.to_s)
    end
  end

  def test_to_s_with_pre_has_three_dots
    with_pre_version("rc1") do
      assert_equal 3, MultiJSON::Version.to_s.count(".")
    end
  end

  private

  def with_pre_version(pre_value)
    original_pre = MultiJSON::Version::PRE
    silence_warnings { MultiJSON::Version.const_set(:PRE, pre_value) }
    yield
  ensure
    silence_warnings { MultiJSON::Version.const_set(:PRE, original_pre) }
  end
end
