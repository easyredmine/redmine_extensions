module EasyQueryParts
  module Settings
    extend ActiveSupport::Concern

    included do
      define_setting :show_sum_row, false
      define_setting :load_groups_opened, true
    end


    module ClassMethods

      def define_setting(name, default)
        define_method(name) do
          settings[name.to_s] || default
        end
        define_method("#{name}=") do |value|
          settings[name.to_s] = value
        end
      end

    end

  end
end
