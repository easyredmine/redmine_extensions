module RedmineExtensions
  module RailsPatches
    module ControllerQueryHelpers

      # ---- PREPARE QUERY LOADING ------
      def loading_group?
        request.xhr? && !!loading_group
      end
      def loading_group
        params[:group_to_load]
      end
      def loading_multiple_groups?
        loading_group? && loading_group.is_a?(Array)
      end


      # *file_type = :csv | :pdf | :ical | ...
      # * args[0] = query | string | symbol
      # * args[1] = optional default string if query entity name is not in langfile
      def get_export_filename(file_type, *args)
        obj = args.first
        if obj.respond_to?(:entity)
          query = obj
          entity = query.entity.name
          if query.new_record?
            name = l("label_#{entity.underscore}_plural", :default => args[1] || entity.underscore.humanize)
          else
            name = query.name
          end
        else
          name = obj && l(obj, :default => obj.to_s.humanize) || 'export'
        end

        return name + ".#{file_type}"
      end


      def set_pagination(query=nil, options={})
        return @entity_pages if @entity_pages
        query ||= @query
        case params[:format]
        when 'csv', 'pdf', 'ics', 'xlsx'
          @limit = Setting.issues_export_limit.to_i
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
        else
          @limit = options.key?(:limit) ? options[:limit] : per_page_option
        end

        if ['xml', 'json'].include?(params[:format])
          @entity_count = query.entity_count(options)
          @entity_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params[:page]
        else
          if loading_multiple_groups?
            @entity_counts = Hash.new
            @groups_pages = Hash.new
            loading_group.each do |group|
              @entity_counts[group] = query.count_group_entities(group, options)
              @groups_pages[group] = Redmine::Pagination::Paginator.new @entity_counts[group], @limit, params[:page]
            end
            @entity_pages = @groups_pages[loading_group.first]
          else
            @entity_count = ( loading_group? ? query.count_group_entities(loading_group, options) : query.entity_count_for_list(options) )
            @entity_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params[:page]
          end
        end
      end

      # Prepare variable @entities, @entity_pages, also sets @offset, @order and @limit variables
      # @param query[EasyQuery] optional argument fallback to @query
      # @param options[Hash] optional argument with sql options, if not given, defaults to {order: sort_clause, limit: @limit, offset: @offset}
      # @return entities to render or nil if there is no next page to render
      def prepare_easy_query_render(query=nil, options={})
        query ||= @query

        entity_pages = set_pagination(query, options)

        return if request.xhr? && entity_pages.last_page.to_i < params['page'].to_i

        # used even there is a multiple groups. hope it all loaded at same page :)
        options[:order] ||= sort_clause
        options[:limit] ||= @limit
        options[:offset] ||= (@offset || entity_pages.offset)

        if query.grouped? && params[:easy_query_q].blank?
          if api_request? || %w(ics atom).include?(params[:format])
            @entities = query.entities(options)
          elsif %w(pdf csv xlsx).include?(params[:format])
            @entities = query.prepare_export_result(options)
          else
            query.prepare_table_render
            if loading_multiple_groups?
              @entities = Hash.new
              loading_group.each {|group| @entities[group] = query.entities_for_group(group, options) }
            elsif loading_group?
              @entities = query.entities_for_group(loading_group, options)
            else
              @entities = query.groups(options)
            end
          end
        else
          case params[:format]
          when 'pdf', 'csv', 'xlsx'
            @entities = query.prepare_export_result(options)
          else
            query.prepare_table_render
            @entities = query.entities(options)
          end
        end

        @entities
      end

      # Renders easy query
      # @param query[EasyQuery] optional argument fallback to @query
      # @param action[String] optional argument fallback to 'index'
      def render_easy_query_html(query=nil, action=nil, locals={})
        query ||= @query

        if request.xhr? && @entity_pages && @entity_pages.last_page.to_i < params[:page].to_i
          render_404
          return false
        end

        locals_options = params[:view_options] || {}
        # On view is default 30 but some queries have 25
        locals_options[:group_limit] ||= @limit

        locals = {query: query, entities: @entities, options: locals_options}.merge(locals)

        if request.xhr? && params[:easy_query_q]
          render :partial => 'easy_queries/easy_query_entities_list', :locals => locals
        elsif loading_group?
          render_options = {:partial => 'easy_queries/easy_query_entities', :locals => locals }
          if @entities.is_a?(Hash)
            groups = Hash.new
            @entities.each do |group, entities|
              @entity_count = @entity_counts[group] if @entity_counts
              @entity_pages = @groups_pages[group] if @groups_pages
              render_options[:locals][:entities] = entities
              groups[group] = render_to_string render_options
            end
            render :json => groups
          else
            render render_options
          end
        else
          render :action => action, :layout => !request.xhr?
        end
      end

      def render_easy_query_xlsx(options={})
        query = options[:query] || @query
        title ||= options[:title] || l("label_#{query.entity.name.pluralize.underscore}", default: 'Xlsx export')
        send_file_headers! :type => Mime::XLSX, :filename => get_export_filename(:xlsx, query, title)
        render 'common/easy_query_index'
      end

      def render_easy_query_pdf(options={})
        query = options[:query] || @query
        title ||= options[:title] || l("label_#{query.entity.name.pluralize.underscore}", default: 'Pdf export')
        send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query, options[:filename] || title )
        render 'common/easy_query_index', locals: { default_title: title }
      end

      def render_easy_query(options={})
        if request.xhr? && !@entities
          render_404
          return false
        end

        query = options[:query] || @query
        entity_name = query.entity.name.pluralize.underscore
        title = options[:title] || l("label_#{entity_name}",  default: l("heading_#{entity_name}_index") )
        pdf_title = options[:pdf_title] || options[:export_title] || title
        csv_title = options[:csv_title] || options[:export_title] || get_export_filename(:csv, @query, title)
        xlsx_title = options[:xlsx_title] || options[:export_title] || title

        respond_to do |format|
          format.html { render_easy_query_html(query, options[:action], options[:html_locals] || {}) }
          format.csv  { send_data(export_to_csv(@entities, @query), filename: csv_title) }
          format.pdf  { render_easy_query_pdf( query: query, filename: title, title: pdf_title) }
          #TODO: hook? format.xlsx { render_easy_query_xlsx(query: query, title: xlsx_title ) }
          format.api
        end
      end

      def index_for_easy_query(entity_klass, default_sort = [[]], options = {})
        retrieve_easy_query(entity_klass)

        options[:query] = @query

        sort_init(@query.sort_criteria.empty? ? default_sort : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        prepare_easy_query_render(@query, options)

        render_easy_query(options)
      end


      # ---- QUERY RETRIEVE -----

      def easy_query_session_stored_params
        [:group_by, :show_sum_row, :load_groups_opened, :column_names, :period_start_date, :period_end_date, :period_date_period, :period_date_period_type, :show_avatars]
      end

      def entity_session_project_id_changed?(entity_query)
        entity_session = entity_query.name.underscore
        session[entity_session][:project_id] != @project.try(:id)
      end

      # -----------------------------------------
      # retrieve query for entity - EasyIssueQuery, EasyUserQuery ...
      def retrieve_easy_query(entity_query, options={})
        entity_session = entity_query.name.underscore
        load_params = false
        if !params[:query_id].blank?
          cond = ''
          unless options[:skip_project_cond] # Filter belongs to project and is using without project
            cond << 'project_id IS NULL'
            if @project
              cond << " OR project_id = #{@project.id}"
              cond << " OR (is_for_subprojects = #{@project.class.connection.quoted_true} AND project_id IN (#{@project.ancestors.select("#{Project.table_name}.id").to_sql}))" unless @project.root?
            end
          end

          @query = entity_query.where(cond).find(params[:query_id])
          raise ::Unauthorized unless @query.visible?
          @query.project = @project

          @query.set_additional_params(options[:query_param] ? params[options[:query_param]] : params)
          session[entity_session] = {:id => @query.id, :project_id => @query.project_id}
          sort_clear
        elsif params[:set_filter] || session[entity_session].nil? || entity_session_project_id_changed?(entity_query)
          # Give it a name, required to be valid
          @query = entity_query.new(:name => "_", :project => (@project unless options[:dont_use_project]))
          load_params = true
          session[entity_session] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :show_sum_row => @query.show_sum_row?, :load_groups_opened => @query.load_groups_opened?, period_start_date: @query.period_start_date, period_end_date: @query.period_end_date, period_date_period: @query.period_date_period, period_date_period_type: @query.period_date_period_type, :show_avatars => @query.show_avatars? } if options[:use_session_store]
          sort_clear if params[:set_filter] == '0'
        else
          @query = nil
          if api_request? && params[:force_use_from_session].blank?
            @query = entity_query.new(:name => '_')
            @query.project = @project unless options[:dont_use_project]
          else
            @query = entity_query.find(session[entity_session][:id]) if session[entity_session][:id] && entity_query.exists?(session[entity_session][:id])
            if @query.nil?
              @query = entity_query.new( session[entity_session].select{|key, value| easy_query_session_stored_params.include?(key.to_sym) }.merge( name: "_", project: @project ) )
              @query.filters = session[entity_session][:filters] if session[entity_session][:filters]
            end
          end
          @query.project = @project unless options[:dont_use_project]
        end

        @query = EasyQueryPresenter.new(@query, view_context)
        @query.from_params(options[:query_param] ? params[options[:query_param]] : params) if load_params

        @query.loading_group = loading_group
        @query
      end

    end
  end
end
