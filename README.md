# Redmine Extensions
[![Gem Version](https://badge.fury.io/rb/redmine_extensions.svg)](http://badge.fury.io/rb/redmine_extensions)
[![Build Status](https://travis-ci.org/easyredmine/redmine_extensions.svg?branch=master)](https://travis-ci.org/easyredmine/redmine_extensions)

This gem provides an extended funcionality for a Redmine project

## Provided funcionalities
* EasySetting - per project settings
* Redmine Plugin Generator
* Redmine Entity Generator

## Redmine Plugin Generator 

Description:
    The plugin generator creates stubs for a new Redmine plugin.
    Plugin is prepared for use in Redmine and Easy Redmine as well.
    You can use --customer flag to generate a special plugin if you can make just a few changes to code. Backup this plugin before Redmine or Easy Redmine upgrade and move back for keep you changes.

Example:
    rails g redmine_extensions:plugin NameOfNewPlugin
      create  plugins/name_of_new_plugin/app/controllers
      ...

Help:
     rails g redmine_extensions:plugin --help


## Redmine Entity Generator

Description:
    The entity generator creates new entity for Redmine plugin.
    New entity is prepared for use in Redmine and Easy Redmine as well.

Example:
    rails g redmine_extensions:entity NameOfNewPlugin Post
      create  plugins/name_of_new_plugin/app/controllers
      ...

Help:
    rails g redmine_extensions:entity --help

## Licence
This is published under GPL-2 license.
