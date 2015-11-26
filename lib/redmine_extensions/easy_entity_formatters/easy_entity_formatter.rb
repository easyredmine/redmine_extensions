class EasyEntityFormatter
  include Rails.application.routes.url_helpers

  def initialize(view_context)
    @view_context = view_context
  end

  def view
    @view_context
  end

  def l(*args)
    view.l(*args)
  end

  def format_object(value)
    view.format_object(value)
  end

end
