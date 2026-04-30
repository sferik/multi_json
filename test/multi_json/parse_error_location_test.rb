# frozen_string_literal: true

require_relative "../test_helper"

# Tests for the line/column location extraction that ParseError runs
# against the underlying adapter's error message.
class ParseErrorLocationTest < Minitest::Test
  cover "MultiJSON::ParseError*"

  def test_line_and_column_default_nil
    error = MultiJSON::ParseError.new

    assert_nil error.line
    assert_nil error.column
  end

  def test_parses_oj_format_with_comma_separator
    # Oj: "expected false (after ) at line 1, column 3 [parse.c:126]"
    error = MultiJSON::ParseError.new("unexpected at line 1, column 3 [parse.c:126]")

    assert_equal 1, error.line
    assert_equal 3, error.column
  end

  def test_parses_json_gem_format_without_comma
    # json gem: "expected object key, got 'foo}' at line 1 column 2"
    error = MultiJSON::ParseError.new("expected object key at line 5 column 17")

    assert_equal 5, error.line
    assert_equal 17, error.column
  end

  def test_parses_line_without_column
    error = MultiJSON::ParseError.new("something failed at line 42")

    assert_equal 42, error.line
    assert_nil error.column
  end

  def test_leaves_line_column_nil_when_message_lacks_location
    error = MultiJSON::ParseError.new("lexical error: invalid char in json text")

    assert_nil error.line
    assert_nil error.column
  end

  def test_case_insensitive_match
    error = MultiJSON::ParseError.new("error at Line 7, Column 9")

    assert_equal 7, error.line
    assert_equal 9, error.column
  end

  def test_handles_invalid_utf8_in_message
    # Adapter error messages sometimes embed bytes from the failing
    # input. Simulate that by prefixing a valid location fragment with
    # invalid UTF-8 bytes tagged as UTF-8 — the ``scrub`` step replaces
    # the invalid bytes so the regex can still match.
    bad = (+"\x82\xAC at line 4 column 6").force_encoding(Encoding::UTF_8)

    refute_predicate bad, :valid_encoding?
    error = MultiJSON::ParseError.new(bad)

    assert_equal 4, error.line
    assert_equal 6, error.column
  end

  def test_handles_ascii_8bit_message_with_high_bytes
    # The regex is pure ASCII so it matches against any encoding;
    # verify the ASCII location fragment is still found even when the
    # message is tagged as binary with high bytes.
    bad = (+"bad\xFFbytes at line 3 column 5").force_encoding(Encoding::ASCII_8BIT)
    error = MultiJSON::ParseError.new(bad)

    assert_equal 3, error.line
    assert_equal 5, error.column
  end
end
