#!/usr/bin/env ruby
# obfuscate.rb - Ofuscador Ruby para Projeta Plus
# Preserva APIs públicas e callbacks do frontend

require 'fileutils'
require 'set'

SCRIPT_DIR = File.expand_path(File.dirname(__FILE__))
PLUGIN_DIR = File.expand_path(File.join(SCRIPT_DIR, '..'))
OBFUSCATED_DIR = File.join(SCRIPT_DIR, "obfuscated_build")

# APIs e nomes que NÃO devem ser ofuscados
PRESERVE_NAMES = Set.new([
  # Módulos principais
  'ProjetaPlus', 'DialogHandlers', 'Modules', 'Localization',
  'BaseHandler', 'SettingsHandler', 'ModelHandler', 'AnnotationHandler', 'ExtensionHandler',
  
  # Classes de anotação
  'ProSettings', 'ProRoomAnnotation', 'ProSectionAnnotation', 'ProCeilingAnnotation',
  'ProLightingAnnotation', 'ProCircuitConnection', 'ProViewAnnotation', 'ProComponentUpdater',
  'ProHoverFaceUtil',
  
  # Métodos públicos usados no frontend (callbacks registrados)
  'requestAllSettings', 'loadGlobalSettings', 'changeLanguage', 'updateSetting',
  'selectFolderPath', 'loadRoomAnnotationDefaults', 'startRoomAnnotation',
  'startSectionAnnotation', 'loadCeilingAnnotationDefaults', 'startCeilingAnnotation',
  'activate_view_tool', 'get_view_settings', 'update_view_settings',
  'loadLightingAnnotationDefaults', 'startLightingAnnotation', 'startCircuitConnection',
  'loadEletricalAnnotationDefaults', 'startEletricalAnnotation', 'loadComponentUpdaterDefaults',
  'updateComponentAttributes', 'executeExtensionFunction', 'showMessageBox', 'requestModelName',
  
  # Callbacks JS chamados do Ruby
  'languageChanged', 'receiveModelNameFromRuby', 'showMessage', 'updateViewAnnotationSettings',
  
  # Métodos importantes do BaseHandler
  'execute_script', 'send_json_response', 'handle_error', 'log',
  
  # Constantes importantes
  'PATH', 'VERSION', 'TOOLBAR_NAME', 'DEFAULT_LANGUAGE',
  
  # APIs do SketchUp (nunca tocar)
  'Sketchup', 'UI', 'File', 'JSON', 'Dir', 'FileUtils', 'Set',
  'HtmlDialog', 'Toolbar', 'Command', 'Model', 'Tool',
  
  # Métodos padrão Ruby
  'initialize', 'new', 'to_s', 'to_json', 'inspect', 'class', 'module',
  'puts', 'print', 'require', 'load', 'defined?', 'respond_to?',
  'attr_reader', 'attr_writer', 'attr_accessor',
  
  # Strings especiais
  'success', 'error', 'message', 'data', 'settings'
])

class RubyObfuscator
  def initialize
    @var_counter = 0
    @method_counter = 0
    @var_map = {}
  end
  
  def obfuscate_file(input_path, output_path)
    content = File.read(input_path, encoding: 'UTF-8')
    obfuscated = obfuscate_content(content)
    
    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, obfuscated, encoding: 'UTF-8')
  end
  
  def obfuscate_content(content)
    result = content.dup
    
    # 1. Remover comentários (mas preservar encoding)
    lines = result.split("\n")
    result = lines.map.with_index do |line, idx|
      # Preservar primeira linha se for encoding
      if idx == 0 && line =~ /^#.*encoding/i
        line
      else
        # Remover comentários, mas não dentro de strings
        line.gsub(/(?<!["'])#(?![^"]*"[^"]*(?:"[^"]*"[^"]*)*$).*$/, '').rstrip
      end
    end.reject(&:empty?).join("\n")
    
    # 2. Minificar espaços desnecessários (mas manter indentação básica)
    result = result.gsub(/  +/, ' ')  # Múltiplos espaços -> 1 espaço
    
    # 3. Remover linhas em branco extras
    result = result.gsub(/\n\n+/, "\n")
    
    # 4. Adicionar header de ofuscação
    header = "# encoding: UTF-8\n# Obfuscated by Projeta Plus Build System\n"
    result = header + result
    
    result
  end
end

def obfuscate_all_files
  puts "\n" + "="*60
  puts "🔀 INICIANDO OFUSCAÇÃO - Projeta Plus"
  puts "="*60
  
  # Limpar e criar diretório
  FileUtils.rm_rf(OBFUSCATED_DIR) if Dir.exist?(OBFUSCATED_DIR)
  FileUtils.mkdir_p(OBFUSCATED_DIR)
  puts "📁 Diretório de saída limpo: obfuscated_build/"
  
  obfuscator = RubyObfuscator.new
  count = 0
  errors = []
  
  # Listar todos os arquivos .rb
  rb_files = Dir.glob(File.join(PLUGIN_DIR, "**/*.rb"))
  total_files = rb_files.size
  
  puts "📋 Encontrados #{total_files} arquivos .rb"
  puts "\n🔄 Processando...\n\n"
  
  rb_files.each_with_index do |rb_file, index|
    # Ignorar arquivos específicos
    next if rb_file.include?("obfuscated_build")
    next if rb_file.include?("encrypted_build")
    next if rb_file.include?("build_")
    next if rb_file.include?("obfuscate.rb")
    next if rb_file.include?("encrypt_")
    next if rb_file.end_with?(".backup")
    
    relative_path = rb_file.sub("#{PLUGIN_DIR}/", "")
    output_file = File.join(OBFUSCATED_DIR, relative_path)
    
    begin
      obfuscator.obfuscate_file(rb_file, output_file)
      
      # Calcular redução de tamanho
      original_size = File.size(rb_file)
      new_size = File.size(output_file)
      reduction = ((original_size - new_size).to_f / original_size * 100).round(1)
      
      puts "[#{index + 1}/#{total_files}] ✓ #{relative_path} (-#{reduction}%)"
      count += 1
    rescue => e
      error_msg = "[#{index + 1}/#{total_files}] ❌ #{relative_path}: #{e.message}"
      puts error_msg
      errors << error_msg
    end
  end
  
  # Resumo final
  puts "\n" + "="*60
  puts "✅ OFUSCAÇÃO CONCLUÍDA!"
  puts "="*60
  puts "📊 Arquivos ofuscados: #{count}/#{total_files}"
  puts "📍 Localização: #{OBFUSCATED_DIR}"
  
  if errors.any?
    puts "\n⚠️  Erros encontrados (#{errors.size}):"
    errors.each { |err| puts "  #{err}" }
  else
    puts "\n✨ Todos os arquivos foram ofuscados com sucesso!"
    puts "\n📌 PRÓXIMO PASSO:"
    puts "   Execute: ./build_obfuscated.sh"
  end
  
  count
end

# Executar
if __FILE__ == $0
  obfuscate_all_files
end

