# frozen_string_literal: true

# Stubbing and method replacement helpers for tests
module StubHelpers
  module_function

  def with_stub(object, method_name, replacement, call_original: false, &block)
    original = object.method(method_name)
    metaclass = class << object; self; end
    define_stub_method(metaclass, method_name, replacement, original, call_original)
    block.call
  ensure
    silence_warnings { metaclass.define_method(method_name, original) }
  end

  def define_stub_method(metaclass, method_name, replacement, original, call_original)
    silence_warnings do
      if call_original
        metaclass.define_method(method_name) do |*a, **k, &b|
          replacement.call(*a, **k, &b)
          original.call(*a, **k, &b)
        end
      else
        metaclass.define_method(method_name, replacement)
      end
    end
  end

  def silence_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
