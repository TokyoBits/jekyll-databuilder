# frozen_string_literal: true

require "jekyll-databuilder/version"
require "jekyll-databuilder/arg_parser"
require "jekyll-databuilder/movement_arg_parser"
require "jekyll-databuilder/file_creator"
require "jekyll-databuilder/file_mover"
require "jekyll-databuilder/file_info"
require "jekyll-databuilder/file_editor"

module Jekyll
  module Databuilder
    DEFAULT_TYPE = "md"
    DEFAULT_LAYOUT = "post"
    DEFAULT_LAYOUT_PAGE = "page"
    DEFAULT_DATESTAMP_FORMAT = "%Y-%m-%d"
    DEFAULT_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M %z"
  end
end

%w(s3_uploader compose).each do |file|
  require File.expand_path("jekyll/commands/#{file}.rb", __dir__)
end
