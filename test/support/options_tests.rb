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

  def test_dump_options_allows_objects_with_to_hash
    value = Object.new
    def value.to_hash = {foo: "bar"}
    subject.generate_options = value

    assert_equal({foo: "bar"}, subject.generate_options)
  ensure
    subject.generate_options = nil
  end

  def test_dump_options_evaluates_lambda_with_args
    subject.generate_options = ->(a1, a2) { {a1 => a2} }

    assert_equal({"1" => "2"}, subject.generate_options("1", "2"))
  ensure
    subject.generate_options = nil
  end

  def test_dump_options_evaluates_lambda_without_args
    subject.generate_options = -> { {foo: "bar"} }

    assert_equal({foo: "bar"}, subject.generate_options)
  ensure
    subject.generate_options = nil
  end

  def test_dump_options_returns_empty_hash_for_invalid_values
    [true, false, 10, nil].each do |val|
      subject.generate_options = val

      assert_equal subject.default_generate_options, subject.generate_options
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

  def test_load_options_allows_objects_with_to_hash
    value = Object.new
    def value.to_hash = {foo: "bar"}
    subject.parse_options = value

    assert_equal({foo: "bar"}, subject.parse_options)
  ensure
    subject.parse_options = nil
  end

  def test_load_options_evaluates_lambda_with_args
    subject.parse_options = ->(a1, a2) { {a1 => a2} }

    assert_equal({"1" => "2"}, subject.parse_options("1", "2"))
  ensure
    subject.parse_options = nil
  end

  def test_load_options_evaluates_lambda_without_args
    subject.parse_options = -> { {foo: "bar"} }

    assert_equal({foo: "bar"}, subject.parse_options)
  ensure
    subject.parse_options = nil
  end

  def test_load_options_returns_empty_hash_for_invalid_values
    [true, false, 10, nil].each do |val|
      subject.parse_options = val

      assert_equal subject.default_parse_options, subject.parse_options
    end
  ensure
    subject.parse_options = nil
  end
end
