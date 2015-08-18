module EasyQueryParts
  module Deprecated

    def from_params(params)
      RedmineExtensions::BasePresenter.present(self, nil).from_params(params)
    end

    def to_params
      RedmineExtensions::BasePresenter.present(self, nil).to_params
    end

    deprecate :from_params, :to_params, deprecator: RedmineExtensions::Deprecator.new

  end
end
