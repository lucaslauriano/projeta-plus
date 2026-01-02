# 📋 PROMPT TEMPLATE - Criação de Novos Módulos Ruby para ProjetaPlus

## 🎯 Contexto

Este prompt serve como guia para criar novos módulos Ruby integrados ao sistema ProjetaPlus no SketchUp. Siga este padrão para manter consistência arquitetural.

---

## 📂 Estrutura de Arquivos

projeta_plus/
├── modules/
│ └── [nome-do-modulo]/
│ ├── [nome_do_modulo].rb # Módulo principal
│ └── json_data/ # (Opcional) Dados JSON
│ ├── [nome]data.json # Dados padrão do sistema
│ └── user[nome]\_data.json # Dados do usuário
├── dialog_handlers/
│ └── [nome]\_handlers.rb # Callbacks do diálogo
├── frontend/projeta-plus-html/
│ ├── app/dashboard/[nome]/
│ │ ├── page.tsx # Página principal
│ │ └── components/
│ │ └── [Nome]Component.tsx # Componentes React
│ ├── hooks/
│ │ └── use[Nome].ts # Hook customizado
│ └── types/
│ └── global.d.ts # Tipos TypeScript

---

## 🔧 PADRÃO 1: Estrutura do Módulo Ruby

### **Localização:**

`projeta_plus/modules/[nome-do-modulo]/[nome_do_modulo].rb`

### **Template Base:**

```ruby
# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module [NomeDoModulo]

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      # Buscar de Settings quando possível
      SETTINGS_KEY = "[modulo]_settings"

      # Paths para arquivos JSON
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, '[nome]_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_[nome]_data.json')

      # ========================================
      # MÉTODOS PÚBLICOS (em inglês)
      # ========================================

      def self.get_[entidade]
        # Retorna dados do modelo SketchUp
        # Formato: { success: true/false, data: [...], message: "..." }
      end

      def self.add_[entidade](params)
        # Adiciona nova entidade ao modelo
        # Valida parâmetros
        # Usa operação transacional
        # Retorna: { success: true/false, message: "...", [entidade]: {...} }
      end

      def self.update_[entidade](name, params)
        # Atualiza entidade existente
        # Valida se existe
        # Usa operação transacional
        # Retorna: { success: true/false, message: "..." }
      end

      def self.delete_[entidade](name)
        # Remove entidade do modelo
        # Valida se pode ser removida
        # Usa operação transacional
        # Retorna: { success: true/false, message: "..." }
      end

      # ========================================
      # MÉTODOS DE PERSISTÊNCIA JSON
      # ========================================

      def self.save_to_json(json_data)
        # Salva em USER_DATA_FILE
        # Cria diretório se não existir
        # Retorna: { success: true/false, message: "...", path: "..." }
      end

      def self.load_from_json
        # Prioridade 1: USER_DATA_FILE
        # Prioridade 2: DEFAULT_DATA_FILE
        # Remove BOM UTF-8
        # Retorna: { success: true/false, data: {...}, message: "..." }
      end

      def self.load_default_data
        # Sempre carrega DEFAULT_DATA_FILE
        # Cria cópia em USER_DATA_FILE
        # Retorna: { success: true/false, data: {...}, message: "..." }
      end

      def self.load_from_file
        # UI.opendialog para selecionar arquivo
        # Valida JSON
        # Não salva automaticamente
        # Retorna: { success: true/false, data: {...}, message: "..." }
      end

      # ========================================
      # MÉTODOS DE EXPORTAÇÃO (OBRIGATÓRIO PARA RELATÓRIOS)
      # ========================================

      def self.export_csv(report_type, file_path)
        # IMPORTANTE: file_path é OBRIGATÓRIO (fornecido pelo usuário via UI.savepanel)
        # Valida modelo ativo
        # Valida path fornecido
        # Garante extensão .csv
        # Busca dados com get_report_data
        # Valida se há dados para exportar
        # Escreve CSV com encoding UTF-8
        # Retorna: { success: true/false, message: "...", path: "..." }
      end

      def self.export_xlsx(report_type, file_path)
        # IMPORTANTE: file_path é OBRIGATÓRIO
        # Verifica plataforma (XLSX só funciona no Windows via WIN32OLE)
        # No macOS: retorna erro orientando usar CSV
        # No Windows: pode usar WIN32OLE ou converter CSV
        # Garante extensão .xlsx
        # Retorna: { success: true/false, message: "...", path: "..." }
      end

      # ========================================
      # MÉTODOS DE IMPORTAÇÃO
      # ========================================

      def self.import_to_model(json_data)
        # Cria entidades no modelo SketchUp
        # Usa operação transacional
        # Pode criar indicadores visuais
        # Retorna: { success: true/false, message: "...", count: N }
      end

      # ========================================
      # MÉTODOS PRIVADOS (auxiliares)
      # ========================================

      private

      def self.validate_[entidade](params)
        # Valida parâmetros obrigatórios
        # Retorna: [true/false, mensagem_erro]
      end

      def self.entity_exists?(name)
        # Verifica se já existe
      end

      def self.ensure_json_directory
        # Cria diretório JSON_DATA_PATH se não existir
      end

      def self.remove_bom(content)
        # Remove BOM UTF-8 se presente
        content.sub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
      end

    end
  end
end

🔧 PADRÃO 2: Handler de Callbacks
Localização:
projeta_plus/dialog_handlers/[nome]_handlers.rb

Template Base:


# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/[nome-do-modulo]/[nome_do_modulo].rb'

module ProjetaPlus
  module DialogHandlers
    class [Nome]Handler < BaseHandler

      def register_callbacks
        register_[nome]_callbacks
      end

      private

      def register_[nome]_callbacks

        # GET - Buscar dados
        @dialog.add_action_callback("get[Entidade]") do |action_context|
          begin
            result = ProjetaPlus::Modules::[NomeDoModulo].get_[entidade]
            @dialog.execute_script("window.handleGet[Entidade]Result(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleGet[Entidade]Result(#{error_result.to_json})")
          end
          nil
        end

        # ADD - Adicionar entidade
        @dialog.add_action_callback("add[Entidade]") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::[NomeDoModulo].add_[entidade](params)
            @dialog.execute_script("window.handleAdd[Entidade]Result(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleAdd[Entidade]Result(#{error_result.to_json})")
          end
          nil
        end

        # UPDATE - Atualizar entidade
        @dialog.add_action_callback("update[Entidade]") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::[NomeDoModulo].update_[entidade](name, params)
            @dialog.execute_script("window.handleUpdate[Entidade]Result(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleUpdate[Entidade]Result(#{error_result.to_json})")
          end
          nil
        end

        # DELETE - Remover entidade
        @dialog.add_action_callback("delete[Entidade]") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::[NomeDoModulo].delete_[entidade](name)
            @dialog.execute_script("window.handleDelete[Entidade]Result(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleDelete[Entidade]Result(#{error_result.to_json})")
          end
          nil
        end

        # SAVE TO JSON
        @dialog.add_action_callback("save[Nome]ToJson") do |action_context, json_payload|
          begin
            data = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::[NomeDoModulo].save_to_json(data)
            @dialog.execute_script("window.handleSave[Nome]ToJsonResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleSave[Nome]ToJsonResult(#{error_result.to_json})")
          end
          nil
        end

        # LOAD FROM JSON
        @dialog.add_action_callback("load[Nome]FromJson") do |action_context|
          begin
            result = ProjetaPlus::Modules::[NomeDoModulo].load_from_json
            @dialog.execute_script("window.handleLoad[Nome]FromJsonResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleLoad[Nome]FromJsonResult(#{error_result.to_json})")
          end
          nil
        end

        # PICK SAVE FILE PATH (OBRIGATÓRIO PARA MÓDULOS DE RELATÓRIO)
        @dialog.add_action_callback('pickSaveFilePath') do |_context, payload|
          begin
            params = JSON.parse(payload)
            default_name = params['defaultName'] || 'export'
            file_type = params['fileType'] || 'csv'
            
            extension = file_type == 'xlsx' ? '.xlsx' : '.csv'
            filter = file_type == 'xlsx' ? 'Excel Files|*.xlsx||' : 'CSV Files|*.csv||'
            
            # IMPORTANTE: Usar ::UI para acessar módulo global do SketchUp
            path = ::UI.savepanel("Salvar arquivo #{file_type.upcase}", nil, "#{default_name}#{extension}", filter)
            
            if path
              result = { success: true, path: path }
            else
              result = { success: false, message: 'Salvar cancelado pelo usuário' }
            end
            
            @dialog.execute_script("window.handlePickSaveFilePathResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handlePickSaveFilePathResult(#{error_result.to_json})")
          end
          nil
        end

        # EXPORT CSV (OBRIGATÓRIO PARA MÓDULOS DE RELATÓRIO)
        @dialog.add_action_callback('export[Nome]CSV') do |_context, payload|
          begin
            params = JSON.parse(payload)
            
            unless params['path']
              error_result = { success: false, message: 'Caminho do arquivo não fornecido' }
              @dialog.execute_script("window.handleExport[Nome]CSVResult(#{error_result.to_json})")
              return nil
            end
            
            result = ProjetaPlus::Modules::[NomeDoModulo].export_csv(
              params['reportType'],
              params['path']
            )
            @dialog.execute_script("window.handleExport[Nome]CSVResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleExport[Nome]CSVResult(#{error_result.to_json})")
          end
          nil
        end

        # EXPORT XLSX (OBRIGATÓRIO PARA MÓDULOS DE RELATÓRIO)
        @dialog.add_action_callback('export[Nome]XLSX') do |_context, payload|
          begin
            params = JSON.parse(payload)
            
            unless params['path']
              error_result = { success: false, message: 'Caminho do arquivo não fornecido' }
              @dialog.execute_script("window.handleExport[Nome]XLSXResult(#{error_result.to_json})")
              return nil
            end
            
            result = ProjetaPlus::Modules::[NomeDoModulo].export_xlsx(
              params['reportType'],
              params['path']
            )
            @dialog.execute_script("window.handleExport[Nome]XLSXResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleExport[Nome]XLSXResult(#{error_result.to_json})")
          end
          nil
        end

      end
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleLoad[Nome]FromJsonResult(#{error_result.to_json})")
          end
          nil
        end

        # LOAD DEFAULT
        @dialog.add_action_callback("loadDefault[Nome]") do |action_context|
          begin
            result = ProjetaPlus::Modules::[NomeDoModulo].load_default_data
            @dialog.execute_script("window.handleLoadDefault[Nome]Result(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleLoadDefault[Nome]Result(#{error_result.to_json})")
          end
          nil
        end

        # LOAD FROM FILE
        @dialog.add_action_callback("load[Nome]FromFile") do |action_context|
          begin
            result = ProjetaPlus::Modules::[NomeDoModulo].load_from_file
            @dialog.execute_script("window.handleLoad[Nome]FromFileResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleLoad[Nome]FromFileResult(#{error_result.to_json})")
          end
          nil
        end

        # IMPORT TO MODEL
        @dialog.add_action_callback("import[Nome]ToModel") do |action_context, json_payload|
          begin
            data = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::[NomeDoModulo].import_to_model(data)
            @dialog.execute_script("window.handleImport[Nome]ToModelResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleImport[Nome]ToModelResult(#{error_result.to_json})")
          end
          nil
        end

      end

    end
  end
end

🎨 PADRÃO 3: Hook React/TypeScript
Localização:
projeta_plus/frontend/projeta-plus-html/hooks/use[Nome].ts

Template Base:
'use client';

import { useState, useEffect } from 'react';
import { toast } from 'sonner';

interface [Entidade] {
  name: string;
  // outros campos...
}

interface [Nome]Data {
  entidades: [Entidade][];
  // outras coleções...
}

export function use[Nome]() {
  const [data, setData] = useState<[Nome]Data>({
    entidades: [],
  });
  const [isBusy, setIsBusy] = useState(false);

  // ========================================
  // UTILITY FUNCTIONS
  // ========================================

  const callSketchupMethod = (method: string, params?: any) => {
    if (window.sketchup) {
      window.sketchup[method](params ? JSON.stringify(params) : undefined);
    } else {
      console.warn(`[MOCK MODE] ${method}:`, params);
      // Mock response para desenvolvimento
    }
  };

  // ========================================
  // HANDLERS (recebem respostas do Ruby)
  // ========================================

  useEffect(() => {
    window.handleGet[Entidade]Result = (result: any) => {
      setIsBusy(false);
      if (result.success) {
        setData(result.data);
      } else {
        toast.error(result.message || 'Erro ao carregar');
      }
    };

    window.handleAdd[Entidade]Result = (result: any) => {
      setIsBusy(false);
      if (result.success) {
        toast.success('Adicionado com sucesso!');
        get[Entidade](); // Recarrega
      } else {
        toast.error(result.message || 'Erro ao adicionar');
      }
    };

    window.handleUpdate[Entidade]Result = (result: any) => {
      setIsBusy(false);
      if (result.success) {
        toast.success('Atualizado com sucesso!');
        get[Entidade](); // Recarrega
      } else {
        toast.error(result.message || 'Erro ao atualizar');
      }
    };

    window.handleDelete[Entidade]Result = (result: any) => {
      setIsBusy(false);
      if (result.success) {
        toast.success('Removido com sucesso!');
        get[Entidade](); // Recarrega
      } else {
        toast.error(result.message || 'Erro ao remover');
      }
    };

    window.handleSave[Nome]ToJsonResult = (result: any) => {
      if (result.success) {
        toast.success('Salvo com sucesso!');
      } else {
        toast.error(result.message || 'Erro ao salvar');
      }
    };

    window.handleLoad[Nome]FromJsonResult = (result: any) => {
      if (result.success) {
        setData(result.data);
        toast.success('Carregado com sucesso!');
      } else {
        toast.error(result.message || 'Erro ao carregar');
      }
    };

    window.handleLoadDefault[Nome]Result = (result: any) => {
      if (result.success) {
        setData(result.data);
        toast.success('Dados padrão carregados!');
      } else {
        toast.error(result.message || 'Erro ao carregar padrão');
      }
    };

    window.handleImport[Nome]ToModelResult = (result: any) => {
      if (result.success) {
        toast.success(`${result.count} itens importados!`);
      } else {
        toast.error(result.message || 'Erro ao importar');
      }
    };

    // HANDLERS DE EXPORTAÇÃO (OBRIGATÓRIO PARA MÓDULOS DE RELATÓRIO)
    window.handlePickSaveFilePathResult = (result: any) => {
      // Este handler é resolvido via Promise, não precisa fazer nada aqui
    };

    window.handleExport[Nome]CSVResult = (result: any) => {
      setIsBusy(false);
      if (result.success) {
        toast.success(`Arquivo salvo: ${result.path}`);
      } else {
        toast.error(result.message || 'Erro ao exportar CSV');
      }
    };

    window.handleExport[Nome]XLSXResult = (result: any) => {
      setIsBusy(false);
      if (result.success) {
        toast.success(`Arquivo salvo: ${result.path}`);
      } else {
        toast.error(result.message || 'Erro ao exportar XLSX');
      }
    };

    // Cleanup
    return () => {
      delete window.handleGet[Entidade]Result;
      delete window.handleAdd[Entidade]Result;
      delete window.handleUpdate[Entidade]Result;
      delete window.handleDelete[Entidade]Result;
      delete window.handleSave[Nome]ToJsonResult;
      delete window.handleLoad[Nome]FromJsonResult;
      delete window.handleLoadDefault[Nome]Result;
      delete window.handleImport[Nome]ToModelResult;
      delete window.handlePickSaveFilePathResult;
      delete window.handleExport[Nome]CSVResult;
      delete window.handleExport[Nome]XLSXResult;
    };
  }, []);

  // ========================================
  // PUBLIC METHODS
  // ========================================

  const get[Entidade] = () => {
    setIsBusy(true);
    callSketchupMethod('get[Entidade]');
  };

  const add[Entidade] = async (params: Partial<[Entidade]>) => {
    if (!params.name || params.name.trim() === '') {
      toast.error('Nome é obrigatório');
      return false;
    }

    setIsBusy(true);
    callSketchupMethod('add[Entidade]', params);
    return true;
  };

  const update[Entidade] = async (name: string, params: Partial<[Entidade]>) => {
    setIsBusy(true);
    callSketchupMethod('update[Entidade]', { name, ...params });
    return true;
  };

  const delete[Entidade] = async (name: string) => {
    const confirmed = confirm(`Deseja realmente remover "${name}"?`);
    if (!confirmed) return;

    setIsBusy(true);
    callSketchupMethod('delete[Entidade]', { name });
  };

  const saveToJson = () => {
    callSketchupMethod('save[Nome]ToJson', data);
  };

  const loadFromJson = () => {
    callSketchupMethod('load[Nome]FromJson');
  };

  const loadDefault = () => {
    callSketchupMethod('loadDefault[Nome]');
  };

  const loadFromFile = () => {
    callSketchupMethod('load[Nome]FromFile');
  };

  const importToModel = () => {
    callSketchupMethod('import[Nome]ToModel', data);
  };

  const clearAll = () => {
    const confirmed = confirm('Deseja realmente limpar tudo?');
    if (!confirmed) return;

    setData({ entidades: [] });
    toast.info('Dados limpos');
  };

  // MÉTODOS DE EXPORTAÇÃO (OBRIGATÓRIO PARA MÓDULOS DE RELATÓRIO)
  const exportCSV = async (reportType: string) => {
    try {
      setIsBusy(true);
      // Primeiro solicita ao usuário onde salvar o arquivo
      const pathResult = await new Promise<{ success: boolean; path?: string; message?: string }>((resolve) => {
        (window as any).handlePickSaveFilePathResult = (result: any) => resolve(result);
        callSketchupMethod('pickSaveFilePath', { 
          defaultName: reportType, 
          fileType: 'csv' 
        });
      });

      if (!pathResult.success || !pathResult.path) {
        toast.info(pathResult.message || 'Exportação cancelada');
        setIsBusy(false);
        return;
      }

      // Agora exporta para o caminho escolhido
      await callSketchupMethod('export[Nome]CSV', { 
        reportType, 
        path: pathResult.path 
      });
    } catch (error) {
      console.error('Error exporting CSV:', error);
      toast.error('Erro ao exportar CSV');
      setIsBusy(false);
    }
  };

  const exportXLSX = async (reportType: string) => {
    try {
      setIsBusy(true);
      // Primeiro solicita ao usuário onde salvar o arquivo
      const pathResult = await new Promise<{ success: boolean; path?: string; message?: string }>((resolve) => {
        (window as any).handlePickSaveFilePathResult = (result: any) => resolve(result);
        callSketchupMethod('pickSaveFilePath', { 
          defaultName: reportType, 
          fileType: 'xlsx' 
        });
      });

      if (!pathResult.success || !pathResult.path) {
        toast.info(pathResult.message || 'Exportação cancelada');
        setIsBusy(false);
        return;
      }

      // Agora exporta para o caminho escolhido
      await callSketchupMethod('export[Nome]XLSX', { 
        reportType, 
        path: pathResult.path 
      });
    } catch (error) {
      console.error('Error exporting XLSX:', error);
      toast.error('Erro ao exportar XLSX');
      setIsBusy(false);
    }
  };

  // ========================================
  // LIFECYCLE
  // ========================================

  useEffect(() => {
    get[Entidade]();
  }, []);

  // ========================================
  // RETURN
  // ========================================

  return {
    data,
    isBusy,
    get[Entidade],
    add[Entidade],
    update[Entidade],
    delete[Entidade],
    saveToJson,
    loadFromJson,
    loadDefault,
    loadFromFile,
    exportCSV,     // Para módulos de relatório
    exportXLSX,    // Para módulos de relatório
    importToModel,
    clearAll,
  };
}

🎨 PADRÃO 4: Tipos TypeScript
Localização:
global.d.ts

Adicionar:

// [Nome] Module
handleGet[Entidade]Result?: (result: any) => void;
handleAdd[Entidade]Result?: (result: any) => void;
handleUpdate[Entidade]Result?: (result: any) => void;
handleDelete[Entidade]Result?: (result: any) => void;
handleSave[Nome]ToJsonResult?: (result: any) => void;
handleLoad[Nome]FromJsonResult?: (result: any) => void;
handleLoadDefault[Nome]Result?: (result: any) => void;
handleLoad[Nome]FromFileResult?: (result: any) => void;
handleImport[Nome]ToModelResult?: (result: any) => void;

📋 CHECKLIST DE IMPLEMENTAÇÃO
Backend Ruby:
 Criar módulo em modules/[nome-do-modulo]/[nome_do_modulo].rb
 Seguir padrão de nomenclatura (métodos em inglês)
 Implementar métodos públicos: get_, add_, update_, delete_
 Implementar persistência JSON: save_to_json, load_from_json, load_default_data
 Usar operações transacionais (start_operation, commit_operation)
 Validar parâmetros antes de processar
 Retornar sempre { success: true/false, message: "...", data: {...} }
 Criar constantes para paths e configurações
 Buscar de Settings quando aplicável
 Adicionar encoding UTF-8 no topo do arquivo
 Tratar erros com rescue e retornar mensagens claras

Handler de Callbacks:
 Criar handler em dialog_handlers/[nome]_handlers.rb
 Herdar de BaseHandler
 Registrar todos os callbacks necessários
 Fazer parse do JSON recebido
 Chamar métodos do módulo correspondente
 Executar script JavaScript com resultado
 Tratar erros e enviar resposta de erro ao frontend
 Retornar nil no final de cada callback
Frontend Hook:
 Criar hook em hooks/use[Nome].ts
 Definir interfaces TypeScript para entidades
 Implementar estado com useState
 Implementar handlers para receber respostas do Ruby
 Criar função callSketchupMethod para comunicação
 Implementar métodos públicos (add, update, delete, etc)
 Adicionar validações no frontend
 Exibir toast notifications para feedback
 Implementar modo mock para desenvolvimento
 Fazer cleanup dos handlers no useEffect
 Carregar dados iniciais no mount
Tipos TypeScript:
 Adicionar handlers em types/global.d.ts
 Seguir padrão de nomenclatura: handle[Acao][Entidade]Result
Componentes React:
 Criar página em app/dashboard/[nome]/page.tsx
 Criar componentes em app/dashboard/[nome]/components/
 Usar design system consistente (Button, Input, Badge, etc)
 Aplicar classes Tailwind conforme padrão da aplicação
 Implementar formulários de criação/edição
 Adicionar botões de ação (salvar, carregar, importar, limpar)
 Exibir lista de entidades com opções de editar/deletar
 Adicionar loading states durante operações
Arquivos JSON:
 Criar json_data/[nome]_data.json com dados padrão
 Formato: UTF-8, estruturado, com indentação
 Será criado user_[nome]_data.json automaticamente
 Documentar estrutura do JSON
Registro no Sistema:
 Registrar handler em projeta_plus_dialog_manager.rb
 Adicionar rota no menu do SketchUp (se necessário)
 Adicionar link na navegação do frontend

🎯 CONVENÇÕES E BOAS PRÁTICAS
Ruby:
Encoding: Sempre # encoding: UTF-8 na primeira linha
Métodos: Nomes em inglês, snake_case
Retornos: Sempre Hash com :success, :message, :data
Operações: Usar model.start_operation e commit_operation
Validações: Validar parâmetros antes de processar
Erros: Usar rescue => e e retornar erro estruturado
JSON: Remover BOM UTF-8 ao carregar arquivos
Paths: Usar File.join para compatibilidade cross-platform
Constantes: UPPERCASE para constantes de módulo
Privado: Métodos auxiliares devem ser private
TypeScript:
Tipos: Sempre definir interfaces para entidades
Handlers: Prefixo handle + ação + Result
Métodos: camelCase, verbos no infinitivo
Estados: useState para dados mutáveis
Cleanup: Sempre deletar handlers globais no cleanup
Mock: Suporte a modo desenvolvimento sem SketchUp
Validações: Validar no frontend antes de enviar ao backend
Feedback: Toast para todas as ações do usuário
Loading: Usar isBusy para estados de carregamento
Async: Funções que chamam Ruby devem ser async
Comunicação Ruby ↔ JavaScript:
Ruby → JS: @dialog.execute_script("window.handler(#{json})")
JS → Ruby: window.sketchup.callbackName(JSON.stringify(params))
Formato: Sempre JSON
Encoding: UTF-8
Erro: Sempre incluir success: false e message
📝 EXEMPLO DE USO DO PROMPT

Crie um novo módulo chamado "Materials" que:
- Gerencia materiais personalizados do SketchUp
- Permite criar, editar, deletar e listar materiais
- Cada material tem: nome, cor RGB, textura (path opcional)
- Suporta salvar/carregar de JSON
- Tem dados padrão com 20 materiais comuns
- Importa materiais para o modelo criando amostras visuais (cubos 10cm)

Siga o padrão estabelecido e crie toda a estrutura necessária.

✅ VALIDAÇÃO FINAL
Após criar o módulo, verificar:

 Módulo Ruby funciona standalone (sem erros de sintaxe)
 Handler registra callbacks corretamente
 Frontend hook compila sem erros TypeScript
 Comunicação Ruby ↔ JS funciona (teste manual)
 Operações CRUD funcionam corretamente
 Persistência JSON salva e carrega dados
 Importação para modelo funciona
 Toast notifications aparecem
 Loading states funcionam
 Modo mock funciona para desenvolvimento
 Erros são tratados graciosamente
 Código segue padrões de formatação
 Documentação inline está presente
🎉 Prompt Template Completo! Use este guia para criar novos módulos com consistência arquitetural.


Arquivo criado em: `MODULE_CREATION_TEMPLATE.md`

Este arquivo markdown contém todo o template e padrões para criar novos módulos no sistema ProjetaPlus. Você pode usá-lo como referência sempre que precisar criar um novo módulo! 📚Arquivo criado em: `MODULE_CREATION_TEMPLATE.md`

Este arquivo markdown contém todo o template e padrões para criar novos módulos no sistema ProjetaPlus. Você pode usá-lo como referência sempre que precisar criar um novo módulo! 📚
```
