# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/options_tests"

class OptionsIntegrationTest < Minitest::Test
  cover "MultiJSON::Options*"

  include OptionsTests

  def subject
    MultiJSON
  end
end
