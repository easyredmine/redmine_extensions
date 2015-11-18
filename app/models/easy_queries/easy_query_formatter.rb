class EasyQueryFormatter
  include ActionView::Helpers
  include ActionView::Context
  include ERB::Util
  include ApplicationHelper
  include Rails.application.routes.url_helpers
end
