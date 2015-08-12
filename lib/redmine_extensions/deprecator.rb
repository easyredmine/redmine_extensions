module RedmineExtensions
  class Deprecator

    def deprecation_warning(method_name, message, caller_backtrace = nil)
      caller_backtrace ||= caller(2)
      message = "#{method_name} is deprecated and will be removed from RedmineExtensions in v1.0"
      ActiveSupport::Deprecation.warn message, caller_backtrace
    end

  end
end
