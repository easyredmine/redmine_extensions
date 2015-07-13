require 'redmine_extensions/html_formatting/internals'
require 'redmine_extensions/html_formatting/formatter'
require 'redmine_extensions/html_formatting/helper'

Rails.application.after_initialize do
  Redmine::WikiFormatting.register(:HTML, RedmineExtensions::HTMLFormatting::Formatter, RedmineExtensions::HTMLFormatting::Helper)
end
