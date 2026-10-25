# frozen_string_literal: true

require "json"

# Payloads for the benchmarks, in the shapes and sizes of benchmark.rb's
# matrix: flat objects of scalars, nested records, and arrays of numbers
# and strings. Every one is built from its index alone, so both versions'
# workers parse and generate exactly the same documents.
module DuelPayloads
  COUNTRIES = %w[US DE BR JP IN AU GB CA].freeze
  EVENT_TYPES = %w[create update sync archive].freeze
  RECORD_TYPES = %w[user team account project].freeze

  module_function

  # A Hash of count fields, cycling through integers, floats, strings,
  # booleans, nulls and short arrays of strings
  def flat_scalars(count)
    Array.new(count) { |index| ["field_#{index}", scalar_value(index)] }.to_h
  end

  # A Hash of count user records, each with nested objects and arrays
  def nested_records(count)
    {
      "meta" => {"count" => count, "generated_at" => "2026-01-01T00:00:00Z", "source" => "benchmark"},
      "data" => Array.new(count) { |index| record(index) }
    }
  end

  # A Hash of long arrays of integers, floats, booleans and strings, and
  # a matrix of integers
  def array_heavy(count)
    {
      "ints" => Array.new(count) { |index| index },
      "floats" => Array.new(count) { |index| ((index * 7) % 100_000) / 31.0 },
      "booleans" => Array.new(count, &:even?),
      "strings" => Array.new(count / 2) { |index| token("str", index, 18) },
      "matrix" => Array.new(count / 25) { |row| Array.new(20) { |column| (row * 20) + column } }
    }
  end

  # The JSON text of an object, frozen, as an application receives it
  def json(object) = JSON.generate(object).freeze

  def scalar_value(index)
    case index % 6
    when 0 then index
    when 1 then ((index * 13) % 10_000) / 10.0
    when 2 then token("value", index, 20)
    when 3 then index.even?
    when 4 then nil
    else [token("tag", index, 6), token("tag", index + 1, 6), token("tag", index + 2, 6)]
    end
  end

  def record(index)
    {
      "id" => index,
      "external_id" => token("user", index, 10),
      "type" => RECORD_TYPES[index % RECORD_TYPES.length],
      "active" => (index % 3).zero?,
      "profile" => profile(index),
      "metrics" => metrics(index),
      "events" => Array.new(3) { |offset| event(index + offset) }
    }
  end

  def profile(index)
    {
      "name" => token("name", index, 14),
      "email" => "user#{index}@example.test",
      "country" => COUNTRIES[index % COUNTRIES.length],
      "segments" => Array.new(4) { |offset| token("segment", index + offset, 6) }
    }
  end

  def metrics(index)
    used = index % 500
    {
      "logins" => index * 3,
      "score" => ((index * 17) % 10_000) / 100.0,
      "quota" => {"used" => used, "limit" => 500, "overage" => used > 450}
    }
  end

  def event(index)
    {
      "at" => format("2026-02-%<day>02dT12:%<minute>02d:00Z", day: (index % 28) + 1, minute: index % 60),
      "type" => EVENT_TYPES[index % EVENT_TYPES.length],
      "delta" => (index % 17) - 8
    }
  end

  def token(prefix, index, width) = "#{prefix}_#{index.to_s(36).rjust(width, "0")}"
end
