module EasyQueryParts
  module Searchable
    extend ActiveSupport::Concern

    included do
      attr_accessor :use_free_search, :free_search_question, :free_search_tokens
    end

    def entity_count(options={})
      if self.use_free_search
        self.search_freetext_count(self.free_search_tokens, options)
      else
        super
      end
    end

    def entities(options={})
      if self.use_free_search
        self.search_freetext(self.free_search_tokens, options)
      else
        super
      end
    end

    def searchable_columns
      []
    end

  end
end
