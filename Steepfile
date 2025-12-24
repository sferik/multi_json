D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"
  ignore "lib/multi_json/vendor"
  ignore "lib/multi_json/adapters"

  library "singleton"

  configure_code_diagnostics(D::Ruby.strict) do |hash|
    # module_function creates private instance methods that are difficult to type
    hash[D::Ruby::NoMethod] = :hint
    # Empty hash literals used with ||= pattern
    hash[D::Ruby::UnannotatedEmptyCollection] = :hint
    # Dynamic constant access (adapter::ParseError)
    hash[D::Ruby::UnknownConstant] = :hint
    # set_backtrace with potentially nil backtrace
    hash[D::Ruby::UnresolvedOverloading] = :hint
    # FallbackAny for yield and dynamic methods
    hash[D::Ruby::FallbackAny] = :hint
  end
end
