class EasyQueriesController < ApplicationController

  def new
    @query = params[:type].constantize
  end

  private

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
