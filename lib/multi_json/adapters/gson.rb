# frozen_string_literal: true

require_relative "json_gem"

module MultiJSON
  module Adapters
    # The gson adapter was removed. This name stays so code that refers
    # to it keeps working, and it selects the json_gem adapter.
    Gson = JsonGem
  end
end
