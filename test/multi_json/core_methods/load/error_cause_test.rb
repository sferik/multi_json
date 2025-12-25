require_relative "../../../test_helper"

class LoadErrorCauseTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_error_cause_is_set
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad}") }

    # The cause should be set, not nil
    refute_nil error.cause
    assert_kind_of Exception, error.cause
  end

  def test_load_error_cause_uses_cause_keyword
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad}") }

    # Verify cause is actually set via the cause: keyword
    refute_nil error.cause, "cause should be set via cause: keyword, not cause__mutant__:"
  end

  def test_load_error_sets_cause
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{invalid}") }

    refute_nil error.cause, "cause must be set via cause: keyword argument"
  end
end
