# frozen_string_literal: true

module ObjectSendWithFallbackMixin
  # Syntactic sugar to simplify `foo.respond_to?(:bar) ? foo.bar : otherwise` to `foo.send(:bar) { otherwise }`
  def send(name, *args)
    return yield if !respond_to?(name) && block_given?

    super
  end
end

Object.module_eval do
  prepend ObjectSendWithFallbackMixin
end
