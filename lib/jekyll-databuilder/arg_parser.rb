# frozen_string_literal: true

module Jekyll
  module Databuilder
    class ArgParser
      attr_reader :args, :options, :config

      # TODO: Remove `nil` parameter in v1.0
      def initialize(args, options, config = nil)
        @args = args
        @options = options
        @config = config || Jekyll.configuration(options)
      end

      def validate!
        raise ArgumentError, "You must specify a name." if args.empty?
      end

      def type
        options["extension"] || Jekyll::Databuilder::DEFAULT_TYPE
      end

      def layout
        options["layout"] || Jekyll::Databuilder::DEFAULT_LAYOUT
      end

      def title
        args.join " "
      end

      def force?
        !!options["force"]
      end

      def timestamp_format
        options["timestamp_format"] || Jekyll::Databuilder::DEFAULT_TIMESTAMP_FORMAT
      end

      def source
        File.join(config["source"], config["collections_dir"])
          .gsub(%r!^#{Regexp.quote(Dir.pwd)}/*!, "")
      end
    end
  end
end
