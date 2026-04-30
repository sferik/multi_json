# frozen_string_literal: true

module OptionsTests
  def test_dump_options_returns_default_if_not_set
    subject.generate_options = nil

    assert_equal subject.default_generate_options, subject.generate_options
  end

  def test_dump_options_returns_frozen_default
    assert_predicate subject.default_generate_options, :frozen?
  end

  def test_dump_options_allows_hashes
    subject.generate_options = {foo: "bar"}

    assert_equal({foo: "bar"}, subject.generate_options)
  ensure
    subject.generate_options = nil
  end

  def test_dump_options_raises_for_non_hash_values
    [true, false, 10, Object.new, "str"].each do |val|
      assert_raises(ArgumentError) { subject.generate_options = val }
    end
  ensure
    subject.generate_options = nil
  end

  def test_load_options_returns_default_if_not_set
    subject.parse_options = nil

    assert_equal subject.default_parse_options, subject.parse_options
  end

  def test_load_options_returns_frozen_default
    assert_predicate subject.default_parse_options, :frozen?
  end

  def test_load_options_allows_hashes
    subject.parse_options = {foo: "bar"}

    assert_equal({foo: "bar"}, subject.parse_options)
  ensure
    subject.parse_options = nil
  end

  def test_load_options_raises_for_non_hash_values
    [true, false, 10, Object.new, "str"].each do |val|
      assert_raises(ArgumentError) { subject.parse_options = val }
    end
  ensure
    subject.parse_options = nil
  end
end
