# frozen_string_literal: true

# What runs around every parse and generate: resolving an adapter by
# name, a block with a temporary adapter, the options cache when it's
# full, and the deprecated names that older callers still use.

require_relative "duel_helper"

duel "adapter: resolve one by name" do
  MultiJSON.current_adapter(adapter: :oj)
end

duel "adapter: parse in with_adapter" do
  MultiJSON.with_adapter(:oj) { MultiJSON.parse('{"a":1}') }
end

# A store of its own, so that its evictions leave the shared caches
# alone. It holds the most entries it can, and every fetch is of the key
# it evicted longest ago, so every fetch misses and evicts one.
duel "options: a cache miss in a full cache" do
  once do
    @store = MultiJSON::OptionsCache::Store.new
    @keys = Array.new(MultiJSON::OptionsCache.max_cache_size + 1) { |index| {max_nesting: index + 1}.freeze }
    @value = {}.freeze
    @next = 0
    @keys.each { |key| @store.fetch(key) { @value } }
  end
  key = @keys[@next]
  @next = (@next + 1) % @keys.size
  @store.fetch(key) { @value }
end

duel "legacy: MultiJson.load" do
  once { MultiJson.load("{}") } # warns once, before it's timed
  MultiJson.load('{"a":1}')
end

duel "legacy: MultiJSON.dump" do
  once do
    MultiJSON.dump({}) # warns once, before it's timed
    @object = DuelPayloads.flat_scalars(40)
  end
  MultiJSON.dump(@object)
end
