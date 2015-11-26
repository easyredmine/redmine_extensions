class EasyEntityFormatter

  def initialize(view_context)
    @view_context = view_context
  end

  def view
    @view_context
  end

  def l(*args)
    view.l(*args)
  end

  def format_column(column, entity)
    format_object column.value_object(entity)
  end

  def format_object(value)
    view.format_object(value)
  end

  def ending_buttons?
    false
  end

end
