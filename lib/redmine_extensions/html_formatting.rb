require 'redmine_extensions/html_formatting/internals'
require 'redmine_extensions/html_formatting/formatter'
require 'redmine_extensions/html_formatting/helper'

ActionDispatch::Reloader.to_prepare do
  Redmine::WikiFormatting.register(:HTML, RedmineExtensions::HTMLFormatting::Formatter, RedmineExtensions::HTMLFormatting::Helper)
end
