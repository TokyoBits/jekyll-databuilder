# frozen_string_literal: true
require 'aws-sdk'
require 'zip'

module Jekyll
  module Commands    
    class DatabuilderCommand < Command
      def self.init_with_program(prog)
        prog.command(:compose) do |c|
          Jekyll.logger.info "Fetching Data from S3!"
          S3.new().upload_site_to_s3
        end
      end

      def self.options
        [
          ["extension", "-x EXTENSION", "--extension EXTENSION", "Specify the file extension"],
          ["layout", "-l LAYOUT", "--layout LAYOUT", "Specify the document layout"],
          ["force", "-f", "--force", "Overwrite a document if it already exists"],
          ["date", "-d DATE", "--date DATE", "Specify the document date"],
          ["collection", "-c COLLECTION", "--collection COLLECTION", "Specify the document collection"],
          ["post", "--post", "Create a new post (default)"],
          ["draft", "--draft", "Create a new draft"],
          ["config", "--config CONFIG_FILE[,CONFIG_FILE2,...]", Array, "Custom configuration file"],
        ]
      end

      def self.process(args = [], options = {})
        config = configuration_from_options(options)
        params = DatabuilderCommandArgParser.new(args, options, config)
        params.validate!

        document = DatabuilderCommandFileInfo.new(params)

        file_creator = Databuilder::FileCreator.new(document, params.force?, params.source)
        file_creator.create!

        Databuilder::FileEditor.bootstrap(config)
        Databuilder::FileEditor.open_editor(file_creator.file_path)
      end

      class S3
        def initialize()
          @client = Aws::S3::Client.new(region: region, credentials: credentials)
        end

        def upload_site_to_s3
          directory_to_zip = "assets" #"/opt/build/repo/_site/assets"
          output_file = "fukagawa.zip"
          puts "Zipping generated site directory..."
          zf = ZipFileGenerator.new(directory_to_zip, output_file)
          zf.write()

          file = File.read(output_file)
          puts "Uploading zipped file to S3..."
          resp = @client.put_object({ body: file, bucket: bucket_name, key: "fukagawa.zip"})
          puts "Uploading to S3 finished!"
        end
    
        def read_csv_from_s3
          bucket_objects = @client.list_objects(bucket: bucket_name)
          
          csv_directory = "_data"
          Dir.mkdir(csv_directory) unless File.exists?(csv_directory)

          bucket_objects.contents.each do |obj|
            if obj.key.include? ".csv"
              filename = obj.key.split('/').last
              puts "** Saving CSV: #{csv_directory}/#{filename}"
              resp = @client.get_object({ bucket: bucket_name, key: obj.key}, target: "#{csv_directory}/#{filename}")
            end

            assets_directory = "assets/text"
            if obj.key.include? assets_directory
              Dir.mkdir(assets_directory) unless File.exists?(assets_directory)
              filename = obj.key.split('/').last
              resp = @client.get_object({ bucket: bucket_name, key: obj.key}, target: "#{assets_directory}/#{filename}")
            end
          end
        end
    
        private
    
        def region
          ENV['REGION']
        end
    
        def bucket_name
          ENV['BUCKET_NAME']
        end
    
        def credentials
         Aws::Credentials.new(
          ENV['ACCESS_KEY_ID'],
          ENV['SECRET_ACCESS_KEY']
         )
        end
      end

      class DatabuilderCommandArgParser < Databuilder::ArgParser
        def validate!
          if options.values_at("post", "draft", "collection").compact.length > 1
            raise ArgumentError, "You can only specify one of --post, --draft, or --collection COLLECTION."
          end

          super
        end

        def date
          @date ||= options["date"] ? Date.parse(options["date"]) : Time.now
        end

        def collection
          if (coll = options["collection"])
            coll
          elsif options["draft"]
            "drafts"
          else
            "posts"
          end
        end
      end

      class DatabuilderCommandFileInfo < Databuilder::FileInfo
        def initialize(params)
          @params = params
          @collection = params.collection
        end

        def resource_type
          case @collection
          when "posts"  then "post"
          when "drafts" then "draft"
          else
            "file"
          end
        end

        def path
          File.join("_#{@collection}", file_name)
        end

        def file_name
          @collection == "posts" ? "#{date_stamp}-#{super}" : super
        end

        def content(custom_front_matter = {})
          default_front_matter = front_matter_defaults_for(@collection)
          custom_front_matter.merge!(default_front_matter) if default_front_matter.is_a?(Hash)

          super({ "date" => time_stamp }.merge!(custom_front_matter))
        end

        private

        def date_stamp
          @params.date.strftime(Jekyll::Databuilder::DEFAULT_DATESTAMP_FORMAT)
        end

        def time_stamp
          @params.date.strftime(Jekyll::Databuilder::DEFAULT_TIMESTAMP_FORMAT)
        end
      end

      class ZipFileGenerator
        # Initialize with the directory to zip and the location of the output archive.
        def initialize(input_dir, output_file)
          @input_dir = input_dir
          @output_file = output_file
        end
      
        # Zip the input directory.
        def write
          entries = Dir.entries(@input_dir) - %w[. ..]
      
          ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
            write_entries entries, '', zipfile
          end
        end
      
        private
      
        # A helper method to make the recursion work.
        def write_entries(entries, path, zipfile)
          entries.each do |e|
            zipfile_path = path == '' ? e : File.join(path, e)
            disk_file_path = File.join(@input_dir, zipfile_path)
      
            if File.directory? disk_file_path
              recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
            else
              put_into_archive(disk_file_path, zipfile, zipfile_path)
            end
          end
        end
      
        def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
          zipfile.mkdir zipfile_path
          subdir = Dir.entries(disk_file_path) - %w[. ..]
          write_entries subdir, zipfile_path, zipfile
        end
      
        def put_into_archive(disk_file_path, zipfile, zipfile_path)
          zipfile.add(zipfile_path, disk_file_path)
        end
      end
    end
  end
end
