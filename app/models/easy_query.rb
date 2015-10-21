begin
  require_dependency Rails.root.join('plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'app', 'models', 'easy_queries', 'easy_query')
rescue LoadError
  class EasyQuery < Query


    def from_params(params)
      build_from_params(params)
    end

    def entity; end

    def entity_scope
      if entity.respond_to?(:visible)
        entity.visible
      else
        entity
      end
    end

    def entities_scope
      entity_scope.where(statement)
    end

    def entities(options={})
      entities_scope.to_a
    end


  end
end
