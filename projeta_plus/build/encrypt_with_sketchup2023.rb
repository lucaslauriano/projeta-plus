# encoding: UTF-8
# encrypt_with_sketchup2023.rb
# 
# EXECUTAR DENTRO DO SKETCHUP 2023 (Ruby Console)
# 
# Como usar:
# 1. Abra SketchUp 2023
# 2. Window > Ruby Console
# 3. load '/caminho/para/este/arquivo.rb'
# 4. Aguarde finalizar
#

require 'fileutils'

# Configurações
SCRIPT_DIR = File.expand_path(File.dirname(__FILE__))
PLUGIN_DIR = File.expand_path(File.join(SCRIPT_DIR, '..'))
ENCRYPTED_DIR = File.join(SCRIPT_DIR, "encrypted_build")

# Limpar e criar diretório de saída
FileUtils.rm_rf(ENCRYPTED_DIR) if Dir.exist?(ENCRYPTED_DIR)
FileUtils.mkdir_p(ENCRYPTED_DIR)

puts "\n" + "="*70
puts "🔒 CRIPTOGRAFIA COM SKETCHUP 2023"
puts "="*70
puts "📁 Origem: #{PLUGIN_DIR}"
puts "📦 Destino: #{ENCRYPTED_DIR}"
puts ""

# Verificar se estamos no SketchUp
unless defined?(Sketchup)
  puts "❌ ERRO: Este script precisa ser executado dentro do SketchUp 2023!"
  puts "   Abra o SketchUp 2023 e carregue via Ruby Console"
  exit 1
end

# Verificar versão
version = Sketchup.version.to_i
puts "📌 Versão do SketchUp detectada: #{Sketchup.version}"

if version >= 24
  puts "⚠️  AVISO: SketchUp #{version} pode não suportar scramble_script"
  puts "   Recomendado: SketchUp 2023 ou anterior"
end

unless Sketchup.respond_to?(:scramble_script)
  puts "❌ ERRO: Sketchup.scramble_script não está disponível!"
  puts "   Use SketchUp 2023 ou versão anterior"
  exit 1
end

# Coletar todos os arquivos .rb
rb_files = Dir.glob(File.join(PLUGIN_DIR, "**/*.rb"))

# Filtrar arquivos a ignorar
rb_files.reject! do |f|
  f.include?("obfuscated_build") ||
  f.include?("encrypted_build") ||
  f.include?("build/") ||
  f.end_with?(".backup")
end

total_files = rb_files.size
puts "📋 Encontrados #{total_files} arquivos para criptografar"
puts "\n🔄 Processando...\n\n"

count = 0
errors = []

rb_files.each_with_index do |rb_file, index|
  # Calcular caminho de saída
  relative_path = rb_file.sub("#{PLUGIN_DIR}/", "")
  output_file = File.join(ENCRYPTED_DIR, relative_path.sub('.rb', '.rbe'))
  
  # Criar diretório se necessário
  FileUtils.mkdir_p(File.dirname(output_file))
  
  begin
    # Criptografar usando API do SketchUp
    Sketchup.scramble_script(rb_file, output_file)
    
    # Verificar se foi criado
    if File.exist?(output_file)
      original_size = File.size(rb_file)
      encrypted_size = File.size(output_file)
      puts "[#{index + 1}/#{total_files}] ✓ #{relative_path} → .rbe (#{encrypted_size} bytes)"
      count += 1
    else
      error_msg = "[#{index + 1}/#{total_files}] ❌ #{relative_path}: Arquivo não foi criado"
      puts error_msg
      errors << error_msg
    end
    
  rescue => e
    error_msg = "[#{index + 1}/#{total_files}] ❌ #{relative_path}: #{e.message}"
    puts error_msg
    errors << error_msg
  end
end

# Resumo final
puts "\n" + "="*70
puts "✅ CRIPTOGRAFIA CONCLUÍDA!"
puts "="*70
puts "📊 Arquivos criptografados: #{count}/#{total_files}"
puts "📍 Localização: #{ENCRYPTED_DIR}"

if errors.any?
  puts "\n⚠️  Erros encontrados (#{errors.size}):"
  errors.each { |err| puts "  #{err}" }
else
  puts "\n✨ Todos os arquivos foram criptografados com sucesso!"
  puts "\n📌 PRÓXIMO PASSO:"
  puts "   Execute no terminal: cd build && ./build_encrypted.sh"
end

puts "\n" + "="*70

# Retornar contagem para verificação
count
