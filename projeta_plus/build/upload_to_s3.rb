# encoding: UTF-8
require 'aws-sdk-s3'
require 'fileutils'

module ProjetaPlus
  module Build
    class S3Uploader
      
      BUCKET_NAME = 'projeta-plus-components'
      REGION = 'us-east-1' # Ajustar conforme região escolhida
      COMPONENTS_PATH = File.join(__dir__, '..', 'components')
      
      def initialize
        @s3 = Aws::S3::Client.new(
          region: REGION,
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        )
      end
      
      def upload_all
        puts "=" * 60
        puts "Uploading components to S3..."
        puts "Bucket: #{BUCKET_NAME}"
        puts "Region: #{REGION}"
        puts "=" * 60
        
        ['eletrical', 'lightning', 'baseboards'].each do |module_name|
          upload_module(module_name)
        end
        
        puts "=" * 60
        puts "Upload completed successfully!"
        puts "=" * 60
      end
      
      def list_files
        puts "\nFiles to be uploaded:"
        ['eletrical', 'lightning', 'baseboards'].each do |module_name|
          module_path = File.join(COMPONENTS_PATH, module_name)
          next unless File.directory?(module_path)
          
          puts "\n#{module_name.upcase}:"
          Dir.glob("#{module_path}/**/*.skp").each do |file_path|
            relative_path = file_path.sub("#{COMPONENTS_PATH}/", '')
            puts "  - #{relative_path}"
          end
        end
      end
      
      private
      
      def upload_module(module_name)
        module_path = File.join(COMPONENTS_PATH, module_name)
        
        unless File.directory?(module_path)
          puts "[SKIP] Module not found: #{module_name}"
          return
        end
        
        files = Dir.glob("#{module_path}/**/*.skp")
        puts "\n[#{module_name.upcase}] Found #{files.length} files"
        
        files.each_with_index do |file_path, index|
          relative_path = file_path.sub("#{COMPONENTS_PATH}/", '')
          s3_key = relative_path.gsub('\\', '/')
          
          print "  [#{index + 1}/#{files.length}] Uploading: #{File.basename(file_path)}... "
          
          begin
            @s3.put_object(
              bucket: BUCKET_NAME,
              key: s3_key,
              body: File.read(file_path),
              content_type: 'application/octet-stream',
              metadata: {
                'original-filename' => File.basename(file_path),
                'upload-date' => Time.now.iso8601,
                'module' => module_name
              }
            )
            puts "✓"
          rescue => e
            puts "✗ (#{e.message})"
          end
        end
      end
      
    end
  end
end

# Executar
if __FILE__ == $0
  if ENV['AWS_ACCESS_KEY_ID'].nil? || ENV['AWS_SECRET_ACCESS_KEY'].nil?
    puts "ERROR: AWS credentials not found!"
    puts "Please set environment variables:"
    puts "  export AWS_ACCESS_KEY_ID='your-access-key'"
    puts "  export AWS_SECRET_ACCESS_KEY='your-secret-key'"
    exit 1
  end
  
  uploader = ProjetaPlus::Build::S3Uploader.new
  
  # Mostrar arquivos que serão enviados
  uploader.list_files
  
  puts "\nProceed with upload? (y/n)"
  response = gets.chomp.downcase
  
  if response == 'y' || response == 'yes'
    uploader.upload_all
  else
    puts "Upload cancelled."
  end
end

