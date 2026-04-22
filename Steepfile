# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"
  ignore "lib/multi_json/adapters"
  # Adapters that have RBS sigs (and stubbed external library types)
  # are checked. The rest of lib/multi_json/adapters stays ignored
  # because their backing libraries don't ship Steep-friendly types
  # and their wrappers do non-trivial things Steep can't follow.
  check "lib/multi_json/adapters/yajl.rb"
  check "lib/multi_json/adapters/jr_jackson.rb"
  check "lib/multi_json/adapters/gson.rb"
  # JRuby-only Concurrent::Map backend; Steep runs on MRI, where the
  # MutexStore version defines the ``Store`` class.
  ignore "lib/multi_json/options_cache/concurrent_store.rb"

  library "singleton"

  configure_code_diagnostics(D::Ruby.strict) do |hash|
    # module_function creates private instance methods that are difficult to type
    hash[D::Ruby::NoMethod] = :hint
    # set_backtrace has three overloads (String|Array[String], Array[Location], nil)
    # and Steep can't pick one when given a `(Array[String] | nil)` union from
    # `cause.backtrace`. The narrow workaround would change observable
    # behavior (set_backtrace([]) vs set_backtrace(nil) leave a different
    # backtrace on the resulting error), so the hint stays.
    hash[D::Ruby::UnresolvedOverloading] = :hint
  end
end
