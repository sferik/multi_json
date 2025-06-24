require "json/ext"
require_relative "json_common"

module MultiJson
  module Adapters
    # Use the JSON gem to dump/load.
    class JsonGem < JsonCommon
      ParseError = ::JSON::ParserError
    end
  end
end
