# frozen_string_literal: true

# Stubbing and method replacement helpers for tests
module StubHelpers
  module_function

  def with_stub(object, method_name, replacement, call_original: false)
    original = object.method(method_name)
    metaclass = class << object; self; end
    define_stub_method(metaclass, method_name, replacement, original, call_original)
    yield
  ensure
    silence_warnings { metaclass.define_method(method_name, original) }
  end

  def define_stub_method(metaclass, method_name, replacement, original, call_original)
    silence_warnings do
      if call_original
        define_forwarding_stub(metaclass, method_name, replacement, original)
      else
        metaclass.define_method(method_name, replacement)
      end
    end
  end

  # Calls the replacement, then the original. Marked ruby2_keywords so
  # keywords are forwarded without a **k splat, which Ruby 2.7 warns
  # about whenever the stubbed method is called with a positional hash.
  def define_forwarding_stub(metaclass, method_name, replacement, original)
    metaclass.define_method(method_name) do |*a, &b|
      replacement.call(*a, &b)
      original.call(*a, &b)
    end
    metaclass.send(:ruby2_keywords, method_name)
  end

  def silence_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
