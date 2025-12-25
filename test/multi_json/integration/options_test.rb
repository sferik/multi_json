require_relative "../../test_helper"
require_relative "../../support/options_tests"

class OptionsIntegrationTest < Minitest::Test
  cover "MultiJson*"

  include OptionsTests

  def subject
    MultiJson
  end
end
