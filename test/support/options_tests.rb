# frozen_string_literal: true

module OptionsTests
  def test_dump_options_returns_default_if_not_set
    subject.dump_options = nil

    assert_equal subject.default_dump_options, subject.dump_options
  end

  def test_dump_options_returns_frozen_default
    assert_predicate subject.default_dump_options, :frozen?
  end

  def test_dump_options_allows_hashes
    subject.dump_options = {foo: "bar"}

    assert_equal({foo: "bar"}, subject.dump_options)
  ensure
    subject.dump_options = nil
  end

  def test_dump_options_allows_objects_with_to_hash
    value = Object.new
    def value.to_hash = {foo: "bar"}
    subject.dump_options = value

    assert_equal({foo: "bar"}, subject.dump_options)
  ensure
    subject.dump_options = nil
  end

  def test_dump_options_evaluates_lambda_with_args
    subject.dump_options = ->(a1, a2) { {a1 => a2} }

    assert_equal({"1" => "2"}, subject.dump_options("1", "2"))
  ensure
    subject.dump_options = nil
  end

  def test_dump_options_evaluates_lambda_without_args
    subject.dump_options = -> { {foo: "bar"} }

    assert_equal({foo: "bar"}, subject.dump_options)
  ensure
    subject.dump_options = nil
  end

  def test_dump_options_returns_empty_hash_for_invalid_values
    [true, false, 10, nil].each do |val|
      subject.dump_options = val

      assert_equal subject.default_dump_options, subject.dump_options
    end
  ensure
    subject.dump_options = nil
  end

  def test_load_options_returns_default_if_not_set
    subject.load_options = nil

    assert_equal subject.default_load_options, subject.load_options
  end

  def test_load_options_returns_frozen_default
    assert_predicate subject.default_load_options, :frozen?
  end

  def test_load_options_allows_hashes
    subject.load_options = {foo: "bar"}

    assert_equal({foo: "bar"}, subject.load_options)
  ensure
    subject.load_options = nil
  end

  def test_load_options_allows_objects_with_to_hash
    value = Object.new
    def value.to_hash = {foo: "bar"}
    subject.load_options = value

    assert_equal({foo: "bar"}, subject.load_options)
  ensure
    subject.load_options = nil
  end

  def test_load_options_evaluates_lambda_with_args
    subject.load_options = ->(a1, a2) { {a1 => a2} }

    assert_equal({"1" => "2"}, subject.load_options("1", "2"))
  ensure
    subject.load_options = nil
  end

  def test_load_options_evaluates_lambda_without_args
    subject.load_options = -> { {foo: "bar"} }

    assert_equal({foo: "bar"}, subject.load_options)
  ensure
    subject.load_options = nil
  end

  def test_load_options_returns_empty_hash_for_invalid_values
    [true, false, 10, nil].each do |val|
      subject.load_options = val

      assert_equal subject.default_load_options, subject.load_options
    end
  ensure
    subject.load_options = nil
  end
end
