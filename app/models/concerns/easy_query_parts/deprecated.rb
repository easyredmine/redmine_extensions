module EasyQueryParts
  module Deprecated

    def from_params(params)
      RedmineExtensions::BasePresenter.present(self, nil).from_params(params)
    end

    def to_params
      RedmineExtensions::BasePresenter.present(self, nil).to_params
    end

    def operators_by_filter_type
      EasyQueryFilter.operators_by_filter_type
    end

    deprecate :from_params, :to_params, deprecator: RedmineExtensions::Deprecator.new

  end
end
