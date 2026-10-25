# frozen_string_literal: true

# MultiJSON.generate, through the adapter MultiJSON picks by default (the
# JSON gem), across benchmark.rb's shapes and sizes, and through each
# adapter's handling of options such as pretty.

require_relative "duel_helper"

duel "generate: a tiny hash" do
  MultiJSON.generate({"a" => 1})
end

duel "generate: a small flat object" do
  once { @object = DuelPayloads.flat_scalars(40) }
  MultiJSON.generate(@object)
end

duel "generate: a small set of records" do
  once { @object = DuelPayloads.nested_records(8) }
  MultiJSON.generate(@object)
end

duel "generate: a large set of records" do
  once { @object = DuelPayloads.nested_records(384) }
  MultiJSON.generate(@object)
end

duel "generate: a large array-heavy document" do
  once { @object = DuelPayloads.array_heavy(25_000) }
  MultiJSON.generate(@object)
end

duel "generate: pretty" do
  once { @object = DuelPayloads.nested_records(8) }
  MultiJSON.generate(@object, pretty: true)
end

duel "generate: with Oj" do
  MultiJSON.generate({"a" => 1}, adapter: :oj)
end

duel "generate: pretty, with Oj" do
  MultiJSON.generate({"a" => 1}, adapter: :oj, pretty: true)
end

duel "generate: through fast_jsonparser" do
  once { @object = DuelPayloads.nested_records(8) }
  MultiJSON.generate(@object, adapter: :fast_jsonparser)
end
