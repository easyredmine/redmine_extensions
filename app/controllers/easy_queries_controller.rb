class EasyQueriesController < ApplicationController

  before_filter :try_find_optional_project, only: [:new, :create]
  before_filter :find_optional_project_no_auth, :only => [:show, :filters]
  before_filter :create_query, :only => [:new, :create]
  before_filter :find_query, :only => [:edit, :update, :destroy, :load_users_for_copy, :copy_to_users]
  before_filter :check_editable, :only => [:create, :edit, :update, :new, :destroy]
  before_filter :find_easy_page_zone_module_and_easy_query, :only => [:chart, :calendar]
  before_filter :update_query, :only => [:update]
  before_filter :from_params, :only => [:new, :create, :update]


  def new
  end

  def create
    if params[:confirm] && @easy_query.save
      flash[:notice] = l(:notice_successful_create)

      if params[:back_url].present?
        separator = params[:back_url].include?('?') ? '&' : '?'
        redirect_to "#{params[:back_url]}#{separator}query_id=#{@easy_query.id}"
      else
        redirect_to @easy_query.entity_easy_query_path(@easy_query.url_project_id_param => @project, :query_id => @easy_query)
      end
      return
    else
      render :action => 'new'
    end
  end

  def edit
    # before_filter :find_query
  end

  def update
    # before_filter :find_query, :update_query, :from_params
    if @easy_query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default @easy_query.entity_easy_query_path(@easy_query.url_project_id_param => @project, :query_id => @easy_query)
    else
      render :action => 'edit'
    end
  end

  def filters
    if params[:easy_page_zone_module_uuid] && (epmz = EasyPageZoneModule.where({:uuid => params[:easy_page_zone_module_uuid]}).first)
      if epmz.settings.is_a?(Hash)
        settings = epmz.settings
        settings.delete('query_id') if settings['query_type'] == '2'
        params.merge!(settings)
        params[:set_filter] = '1'
      end
      if epmz.easy_pages_id == EasyPage.page_project_overview.id && epmz.entity_id
        @project = Project.find(epmz.entity_id)
      end
    end

    retrieve_easy_query(params[:type].constantize, {:query_param => params[:query_param], :skip_project_cond => true})

    render_with_fallback :partial => 'filters', :prefixes => @query, :locals => {
      :query => @query,
      :modul_uniq_id => params[:modul_uniq_id],
      :block_name => params[:block_name]
    }
  end

  private

    def find_optional_project_no_auth
      render_404 if params[:project_id] && !try_find_optional_project
    end

    # When query is saved URL can have format: project_id=1|2|3
    # => result will be render_404
    def try_find_optional_project
      @project = Project.find(params[:project_id]) if params[:project_id]
    rescue ActiveRecord::RecordNotFound
    end

    def find_query
      begin
        @easy_query = EasyQuery.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        @easy_query = EasyQuery.find(params[:easy_query_id])
      end
      @project = @easy_query.project
      @easy_query.user ||= User.current
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def create_query
      begin
        @easy_query = params[:type].constantize.new(params[:easy_query]) if params[:type]
        @easy_query.user = User.current
      rescue
        render_404
      end
    end

    def check_editable
      render_403 unless @easy_query.editable_by?(User.current)
    end

    def update_query
      @easy_query.attributes = params[:easy_query]
    end

    def from_params
      if params[:query_is_for_all]
        @easy_query.project = nil
        @easy_query.is_for_subprojects = nil
      else
        @easy_query.project = @project
        @easy_query.is_for_subprojects = params[:is_for_subprojects]
      end
      @easy_query = RedmineExtensions::BasePresenter.present(@easy_query, view_context)
      @easy_query.from_params(params)
      @easy_query.visibility = EasyQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project, :global => true) || User.current.admin?
      @easy_query.column_names = nil if params[:default_columns]
    end

    def add_additional_statement_to_query(query)
      if query.is_a?(EasyProjectQuery)
        additional_statement = "#{Project.table_name}.easy_is_easy_template=#{query.class.connection.quoted_false}"
        additional_statement << (' AND ' + Project.visible_condition(User.current))

        if query.additional_statement.blank?
          query.additional_statement = additional_statement
        else
          query.additional_statement << ' AND ' + additional_statement
        end
      end
    end

end
