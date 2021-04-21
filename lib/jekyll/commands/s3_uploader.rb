# frozen_string_literal: true
require 'aws-sdk'
require 'zip'

module Jekyll
  module Commands    
    class DatabuilderCommand < Command
      def self.init_with_program(prog)
        prog.command(:s3_uploader) do |c|
          Jekyll.logger.info "Initializing S3 Uploader"
          S3Uploader.new().upload_site_to_s3
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
      end

      class S3Uploader
        def initialize()
          @client = Aws::S3::Client.new(region: region, credentials: credentials)
        end

        def upload_site_to_s3
          directory_to_zip = "_data" #"/opt/build/repo/_site/assets"
          output_file = "fukagawa.zip"
          puts "Zipping generated site directory..."
          zf = ZipFileGenerator.new(directory_to_zip, output_file)
          zf.write()

          file = File.read(output_file)
          puts "Uploading zipped file to S3..."
          resp = @client.put_object({ body: file, bucket: bucket_name, key: "fukagawa.zip"})
          puts "Uploading to S3 finished!"
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
