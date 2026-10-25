# frozen_string_literal: true

# MultiJSON.parse, through the adapter MultiJSON picks by default (the
# JSON gem), across benchmark.rb's shapes and sizes, and through each
# path that parse takes before and after the adapter: blank and scalar
# input, options, IO input, binary input, and parse errors.

require "stringio"
require_relative "duel_helper"

duel "parse: a tiny object" do
  MultiJSON.parse('{"a":1}')
end

duel "parse: a scalar" do
  MultiJSON.parse("42")
end

duel "parse: blank input" do
  MultiJSON.parse("  \n")
end

duel "parse: a small flat object" do
  once { @json = DuelPayloads.json(DuelPayloads.flat_scalars(40)) }
  MultiJSON.parse(@json)
end

duel "parse: a small set of records" do
  once { @json = DuelPayloads.json(DuelPayloads.nested_records(8)) }
  MultiJSON.parse(@json)
end

duel "parse: a medium set of records" do
  once { @json = DuelPayloads.json(DuelPayloads.nested_records(64)) }
  MultiJSON.parse(@json)
end

duel "parse: a large set of records" do
  once { @json = DuelPayloads.json(DuelPayloads.nested_records(384)) }
  MultiJSON.parse(@json)
end

duel "parse: a large array-heavy document" do
  once { @json = DuelPayloads.json(DuelPayloads.array_heavy(25_000)) }
  MultiJSON.parse(@json)
end

duel "parse: with symbolize_names" do
  once { @json = DuelPayloads.json(DuelPayloads.nested_records(8)) }
  MultiJSON.parse(@json, symbolize_names: true)
end

duel "parse: from an IO" do |n|
  once { @json = DuelPayloads.json(DuelPayloads.nested_records(8)) }
  ios = untimed { Array.new(n) { StringIO.new(@json) } }
  ios.each { |io| MultiJSON.parse(io) }
end

duel "parse: binary-encoded input" do
  once { @json = DuelPayloads.json(DuelPayloads.nested_records(64)).b.freeze }
  MultiJSON.parse(@json)
end

duel "parse: invalid JSON" do
  MultiJSON.parse('{"a":[1,2,')
rescue MultiJSON::ParseError
  nil
end

duel "parse: with Oj" do
  MultiJSON.parse('{"a":1}', adapter: :oj)
end

duel "parse: with fast_jsonparser" do
  MultiJSON.parse('{"a":1}', adapter: :fast_jsonparser)
end
