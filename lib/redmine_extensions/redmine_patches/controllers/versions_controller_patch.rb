module RedmineExtensions
  module RedminePatches
    module Controllers
      module VersionsControllerPatch
        extend ActiveSupport::Concern

        included do
          alias_method_chain :new, :redmine_extensions
        end

        def new_with_redmine_extensions
          @version = @project.versions.build
          @version.safe_attributes = params[:version]

          respond_to do |format|
            format.html { render action: 'new', layout: !request.xhr? }
            format.js
          end
        end

      end
    end
  end
end
