# frozen_string_literal: true

# Backward-compatible alias for the legacy ``MultiJson`` constant name
#
# Downstream code that still writes ``MultiJson.parse(...)`` or
# ``rescue MultiJson::ParseError`` continues to work, but emits a
# one-time deprecation warning pointing at ``MultiJSON``. Each public
# method on {MultiJSON} gets an explicit forwarder defined on this
# module, and constant access resolves via {.const_missing}, so both
# dotted calls and ``::`` constant lookups (including rescue clauses)
# route through the canonical module.
#
# This file is loaded last by the ``multi_json`` entry point so the
# forwarder snapshot below sees the complete {MultiJSON} public API,
# including the deprecated aliases defined in ``deprecated.rb``.
#
# @api public
# @deprecated Use {MultiJSON} (all-caps) instead. Will be removed in v2.0.
module MultiJson
  # Forward every public method MultiJSON exposes through an explicit
  # singleton method on the legacy MultiJson module, so callers that
  # capture the method as a Method object (``MultiJson.method(:load)``)
  # find this forwarder instead of falling back to inherited methods like
  # ``Kernel#load``. The earlier ``method_missing``-based shim left
  # ``MultiJson.method(:load)`` resolving to ``Kernel#load`` (because
  # ``Module#method`` doesn't consult ``method_missing``) and broke
  # libraries (Sawyer, Octokit, Danger) that capture decoders as Method
  # objects. Forwarding eagerly fixes the capture path while preserving
  # the one-time deprecation warning each call emits.
  (::MultiJSON.public_methods - ::Module.public_methods).each do |forwarded|
    define_singleton_method(forwarded) do |*args, **kwargs, &block|
      ::MultiJSON.warn_deprecation_once(:multi_json_constant,
        "The MultiJson constant is deprecated and will be removed in v2.0. Use MultiJSON instead.")
      ::MultiJSON.public_send(forwarded, *args, **kwargs, &block)
    end
  end

  class << self
    # Resolve missing constants to their {MultiJSON} counterparts
    #
    # Enables ``rescue MultiJson::ParseError`` and
    # ``MultiJson::Adapters::Oj`` to keep working during the
    # deprecation cycle.
    #
    # @api public
    # @param name [Symbol] constant name
    # @return [Object] the resolved constant from {MultiJSON}
    # @example
    #   MultiJson::ParseError  # returns MultiJSON::ParseError
    def const_missing(name)
      ::MultiJSON.warn_deprecation_once(:multi_json_constant,
        "The MultiJson constant is deprecated and will be removed in v2.0. Use MultiJSON instead.")
      ::MultiJSON.const_get(name)
    end
  end
end
