require 'redmine_extensions/html_formatting/internals'
require 'redmine_extensions/html_formatting/formatter'
require 'redmine_extensions/html_formatting/helper'

ActiveSupport.on_load(:redmine) do
  Redmine::WikiFormatting.register(:HTML, RedmineExtensions::HTMLFormatting::Formatter, RedmineExtensions::HTMLFormatting::Helper)
end
