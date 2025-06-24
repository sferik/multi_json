require "json/pure"
require_relative "json_common"

module MultiJson
  module Adapters
    # Use JSON pure to dump/load.
    class JsonPure < JsonCommon
      ParseError = ::JSON::ParserError
    end
  end
end
