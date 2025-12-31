# encoding: UTF-8
# Integrado e simplificado conforme tipos oficiais
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
 module Modules
 module ProComponentUpdater

  # ===============================
  # FUNÇÃO DE NORMALIZAÇÃO
  # ===============================
  
  def self.normalizar(texto)
    texto.to_s
      .tr('ÁÀÃÂÄáàãâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÕÔÖóòõôöÚÙÛÜúùûüÇç', 'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc')
  end

  # ===============================
  # MAPEAMENTOS
  # ===============================
  def self.mapear_eletrica(caso)
    case caso
    when "NOVO"      then "1"
    when "EXISTENTE" then "2"
    when "MODIFICAR" then "3"
    when "REMOVER"   then "4"
    else caso
    end
  end

  def self.mapear_hidro_iluminacao(caso)
  case caso
  when "NOVO"      then "1"
  when "EXISTENTE" then "2"
  when "MODIFICAR" then "3"
  when "REMOVER"   then "3"
  else
    # Se for número, converte "4" → "3"
    caso.to_s == "4" ? "3" : caso
  end
end


  # ===============================
  # GET DEFAULTS
  # ===============================
  def self.get_defaults
    {
      last_attribute: Sketchup.read_default("ComponentUpdater", "last_attribute", "scale"),
      last_value: Sketchup.read_default("ComponentUpdater", "last_value", ""),
      last_situation_type: Sketchup.read_default("ComponentUpdater", "last_situation_type", "1")
    }
  end

  # ===============================
  # PRINCIPAL: UPDATE COMPONENT ATTRIBUTES
  # ===============================
  def self.update_component_attributes(args)
    model = Sketchup.active_model
    return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") } if model.nil?

    selection = model.selection
    targets = selection.grep(Sketchup::ComponentInstance)
    return { success: false, message: "Nenhum componente selecionado." } if targets.empty?

    attribute_type  = args['attribute_type'].to_s
    new_value       = args['new_value'].to_s
    situation_type  = (args['situation_type'] || args[:situation_type]).to_s

    # -------------------------------
    # MAPA DE ATRIBUTOS
    # -------------------------------
    attribute_map = {
      'scale'       => 'b002_escala',
      'environment' => 'c001a_ambiente',
      'usage'       => 'c002a_uso',
      'usagePrefix' => 'c002b_uso',
      'situation'   => 'a002_situacao'
    }

    actual_attribute = attribute_map[attribute_type]
    return { success: false, message: "Invalid attribute type: #{attribute_type}" } unless actual_attribute

    # -------------------------------
    # SALVAR PREFERÊNCIAS
    # -------------------------------
    Sketchup.write_default("ComponentUpdater", "last_attribute", attribute_type)
    Sketchup.write_default("ComponentUpdater", "last_value", new_value)
    Sketchup.write_default("ComponentUpdater", "last_situation_type", situation_type)

    # -------------------------------
    # INÍCIO DA OPERAÇÃO
    # -------------------------------
    model.start_operation("Atualizar Atributo #{attribute_type}", true)
    begin
      valor_normalizado =
        if attribute_type.to_s.strip.downcase == 'situation'
          normalizar(situation_type)
        else
          normalizar(new_value)
        end

      puts "=== DEBUG ProComponentUpdater ==="
      puts "Alvo: #{attribute_type}, Valor: #{valor_normalizado}, Situação: #{situation_type}"

      targets.each_with_index do |instance, i|
        tipo_relacao = normalizar(instance.get_attribute("dynamic_attributes", "pro_rela_tipo"))
        puts "[#{i + 1}] #{instance.definition.name} → Tipo: '#{tipo_relacao}'"

        # -------------------------------
        # MAPEAMENTO EXATO POR TIPO
        # -------------------------------
        case tipo_relacao
        when "ELETRICA", "ELETRICAMODULOS", "CLIMA"
          novo_valor = mapear_eletrica(valor_normalizado)
        when "ILUMINACAO", "HIDRO"
          novo_valor = mapear_hidro_iluminacao(valor_normalizado)
        else
          puts "→ Tipo desconhecido: #{tipo_relacao.inspect}"
          novo_valor = valor_normalizado
        end

        puts "   Valor aplicado: #{novo_valor.inspect}"

        # -------------------------------
        # ATUALIZAÇÃO DE ATRIBUTOS DC
        # -------------------------------
        if defined?($dc_observers)
          dc = $dc_observers.get_latest_class
          instance.set_attribute("dynamic_attributes", actual_attribute, novo_valor)
          instance.set_attribute("dynamic_attributes", "_refresh", "TRUE")
          dc.set_attribute(instance, "dynamic_attributes", actual_attribute, novo_valor)
          dc.set_attribute(instance, "dynamic_attributes", "_refresh", "TRUE")

          start_time = Time.now
          dc.redraw_with_undo(instance)
          duration = Time.now - start_time
          puts "   #{duration.round(6)}s para redesenhar #{instance.definition.name}"
        else
          puts "⚠ Plugin Dynamic Components não disponível."
        end
      end

      model.commit_operation
      { success: true, message: ProjetaPlus::Localization.t("messages.component_updater_success") }

    rescue StandardError => e
      model.abort_operation
      { success: false, message: "#{ProjetaPlus::Localization.t("messages.error_updating_components")}: #{e.message}" }
    end
  end

 end
 end
end