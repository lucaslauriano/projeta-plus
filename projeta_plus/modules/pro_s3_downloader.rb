# encoding: UTF-8
require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module ProjetaPlus
  module Modules
    module S3Downloader
      
      # URL do backend que gera URLs assinadas
      # TODO: Substituir pela URL real do seu backend
      API_ENDPOINT = ENV['PROJETA_PLUS_API_ENDPOINT'] || 'https://api.projetaplus.com/signed-url'
      
      CACHE_DIR = File.join(ENV['HOME'] || ENV['USERPROFILE'], '.projeta_plus', 'cache')
      
      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================
      
      def self.download_component(s3_key, local_path = nil)
        begin
          # Definir caminho local se não fornecido
          local_path ||= get_cache_path(s3_key)
          
          # Verificar se já existe no cache
          if File.exist?(local_path)
            return {
              success: true,
              message: 'Component loaded from cache',
              path: local_path,
              cached: true
            }
          end
          
          # Obter URL assinada do backend
          signed_url = get_signed_url(s3_key)
          unless signed_url
            return {
              success: false,
              message: 'Failed to get signed URL from backend'
            }
          end
          
          # Download do arquivo
          result = download_file(signed_url, local_path)
          
          if result[:success]
            result[:cached] = false
          end
          
          result
        rescue => e
          {
            success: false,
            message: "Error downloading component: #{e.message}"
          }
        end
      end
      
      def self.clear_cache
        begin
          if File.directory?(CACHE_DIR)
            FileUtils.rm_rf(CACHE_DIR)
            FileUtils.mkdir_p(CACHE_DIR)
          end
          
          {
            success: true,
            message: 'Cache cleared successfully'
          }
        rescue => e
          {
            success: false,
            message: "Error clearing cache: #{e.message}"
          }
        end
      end
      
      def self.get_cache_size
        begin
          size = 0
          if File.directory?(CACHE_DIR)
            Dir.glob("#{CACHE_DIR}/**/*").each do |file|
              size += File.size(file) if File.file?(file)
            end
          end
          
          {
            success: true,
            size_bytes: size,
            size_mb: (size / 1024.0 / 1024.0).round(2)
          }
        rescue => e
          {
            success: false,
            message: "Error calculating cache size: #{e.message}"
          }
        end
      end
      
      # ========================================
      # MÉTODOS PRIVADOS
      # ========================================
      
      private
      
      def self.get_signed_url(s3_key)
        uri = URI.parse("#{API_ENDPOINT}?key=#{URI.encode_www_form_component(s3_key)}")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = 10
        http.read_timeout = 10
        
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Content-Type'] = 'application/json'
        
        # Adicionar token de autenticação se disponível
        if ENV['PROJETA_PLUS_AUTH_TOKEN']
          request['Authorization'] = "Bearer #{ENV['PROJETA_PLUS_AUTH_TOKEN']}"
        end
        
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          return data['url'] || data['signed_url']
        end
        
        nil
      rescue => e
        puts "[S3Downloader] Error getting signed URL: #{e.message}"
        nil
      end
      
      def self.download_file(url, local_path)
        uri = URI.parse(url)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = 30
        http.read_timeout = 60
        
        request = Net::HTTP::Get.new(uri.request_uri)
        
        response = http.request(request)
        
        unless response.is_a?(Net::HTTPSuccess)
          return {
            success: false,
            message: "Download failed: HTTP #{response.code}"
          }
        end
        
        # Criar diretório se não existir
        FileUtils.mkdir_p(File.dirname(local_path))
        
        # Salvar arquivo
        File.binwrite(local_path, response.body)
        
        {
          success: true,
          message: 'Component downloaded successfully',
          path: local_path
        }
      rescue => e
        {
          success: false,
          message: "Error downloading file: #{e.message}"
        }
      end
      
      def self.get_cache_path(s3_key)
        # Criar estrutura de diretórios no cache
        File.join(CACHE_DIR, s3_key)
      end
      
      def self.ensure_cache_dir
        FileUtils.mkdir_p(CACHE_DIR) unless File.directory?(CACHE_DIR)
      end
      
    end
  end
end

