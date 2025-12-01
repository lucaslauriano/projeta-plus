# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProLayers
      
      def self.get_layers
        model = Sketchup.active_model
        return { folders: [], tags: [] } unless model
        
        layers = model.layers
        result = { folders: [], tags: [] }
        
        if layers.respond_to?(:folders)
          layers.folders.each do |folder|
            folder_data = { name: folder.name, tags: [] }
            folder.layers.each do |layer|
              folder_data[:tags] << {
                name: layer.name,
                visible: layer.visible?,
                color: layer.color.to_a[0..2]
              }
            end
            result[:folders] << folder_data
          end
        end
        
        layers.each do |layer|
          next if layer.name == "Layer0" || layer.name == "Untagged"
          in_folder = false
          if layers.respond_to?(:folders)
            layers.folders.each do |folder|
              if folder.layers.include?(layer)
                in_folder = true
                break
              end
            end
          end
          unless in_folder
            result[:tags] << {
              name: layer.name,
              visible: layer.visible?,
              color: layer.color.to_a[0..2]
            }
          end
        end
        
        result
      end

      def self.add_folder(folder_name)
        model = Sketchup.active_model
        return { success: false, message: "No model" } unless model
        
        return { success: false, message: "Folder name required" } if folder_name.nil? || folder_name.strip.empty?
        
        layers = model.layers
        
        unless layers.respond_to?(:folders)
          return { success: false, message: "Folders not supported in this SketchUp version" }
        end
        
        existing = layers.folders.find { |f| f.name == folder_name }
        return { success: false, message: "Folder already exists" } if existing
        
        model.start_operation("Add Folder", true)
        begin
          folder = layers.add_folder(folder_name)
          model.commit_operation
          return { success: true, message: "Folder created", folder: { name: folder.name } }
        rescue => e
          model.abort_operation
          return { success: false, message: e.message }
        end
      end

      def self.add_tag(tag_name, color_array, folder_name = nil)
        model = Sketchup.active_model
        return { success: false, message: "No model" } unless model
        
        return { success: false, message: "Tag name required" } if tag_name.nil? || tag_name.strip.empty?
        
        layers = model.layers
        
        existing = layers[tag_name]
        return { success: false, message: "Tag already exists" } if existing
        
        model.start_operation("Add Tag", true)
        begin
          layer = layers.add(tag_name)
          
          if color_array && color_array.is_a?(Array) && color_array.length >= 3
            layer.color = Sketchup::Color.new(color_array[0], color_array[1], color_array[2])
          end
          
          if folder_name && folder_name != "root" && layers.respond_to?(:folders)
            folder = layers.folders.find { |f| f.name == folder_name }
            if folder
              begin
                folder.add_layer(layer)
              rescue => e
                puts "Warning: Could not add tag to folder: #{e.message}"
              end
            end
          end
          
          model.commit_operation
          
          return { 
            success: true, 
            message: "Tag created",
            tag: {
              name: layer.name,
              visible: layer.visible?,
              color: layer.color.to_a[0..2]
            }
          }
        rescue => e
          model.abort_operation
          return { success: false, message: e.message }
        end
      end

      def self.delete_folder(folder_name)
        model = Sketchup.active_model
        return { success: false, message: "No model" } unless model
        
        return { success: false, message: "Folder name required" } if folder_name.nil? || folder_name.strip.empty?
        
        layers = model.layers
        
        unless layers.respond_to?(:folders)
          return { success: false, message: "Folders not supported in this SketchUp version" }
        end
        
        folder = layers.folders.find { |f| f.name == folder_name }
        return { success: false, message: "Folder not found" } unless folder
        
        model.start_operation("Delete Folder", true)
        begin
          # Move tags out of folder before deleting
          folder.layers.each do |layer|
            begin
              folder.remove_layer(layer)
            rescue; end
          end
          
          layers.remove_folder(folder)
          model.commit_operation
          return { success: true, message: "Folder deleted" }
        rescue => e
          model.abort_operation
          return { success: false, message: e.message }
        end
      end

      def self.delete_layer(name)
        model = Sketchup.active_model
        return { success: false, message: "No model" } unless model
        
        layers = model.layers
        layer = layers[name]
        return { success: false, message: "Layer not found" } unless layer
        
        if layer.name == "Layer0" || layer.name == "Untagged"
          return { success: false, message: "Cannot delete default layer" }
        end
        
        model.start_operation("Delete Layer", true)
        begin
          layers.remove(layer)
          model.commit_operation
          return { success: true, message: "Layer deleted" }
        rescue => e
          model.abort_operation
          return { success: false, message: e.message }
        end
      end

      def self.toggle_visibility(name, visible)
        model = Sketchup.active_model
        return { success: false, message: "No model" } unless model
        
        layers = model.layers
        layer = layers[name]
        return { success: false, message: "Layer not found" } unless layer
        
        layer.visible = visible
        return { success: true, message: "Visibility updated" }
      rescue => e
        return { success: false, message: e.message }
      end

      def self.get_default_json_path
        plugin_dir = File.dirname(__FILE__)
        json_file = File.join(plugin_dir, 'json_data', 'tags_data.json')
        File.expand_path(json_file)
      end

      def self.get_user_json_path
        plugin_dir = File.dirname(__FILE__)
        json_file = File.join(plugin_dir, 'json_data', 'user_tags_data.json')
        File.expand_path(json_file)
      end

      # Mantém compatibilidade - usa arquivo do usuário
      def self.get_json_path
        get_user_json_path
      end

      def self.save_to_json(json_data)
        begin
          data = json_data.is_a?(String) ? JSON.parse(json_data) : json_data
          json_path = get_user_json_path
          
          dir = File.dirname(json_path)
          Dir.mkdir(dir) unless Dir.exist?(dir)
          
          File.open(json_path, 'w:UTF-8') { |f| f.write(JSON.pretty_generate(data)) }
          return { success: true, message: "Saved to user JSON", path: json_path }
        rescue => e
          return { success: false, message: e.message }
        end
      end

      def self.load_from_json
        # Tenta carregar do arquivo do usuário primeiro
        user_path = get_user_json_path
        if File.exist?(user_path)
          begin
            data = JSON.parse(File.read(user_path, encoding: 'UTF-8'))
            return data.merge({ success: true, message: "Loaded from user JSON" })
          rescue => e
            # Se falhar, tenta carregar do padrão
          end
        end
        
        # Carrega do arquivo padrão
        default_path = get_default_json_path
        return { folders: [], tags: [], success: false, message: "Default file not found" } unless File.exist?(default_path)
        
        begin
          data = JSON.parse(File.read(default_path, encoding: 'UTF-8'))
          return data.merge({ success: true, message: "Loaded from default JSON" })
        rescue => e
          return { folders: [], tags: [], success: false, message: e.message }
        end
      end

      def self.load_default_tags
        # Sempre carrega do arquivo padrão (redefinir)
        default_path = get_default_json_path
        return { folders: [], tags: [], success: false, message: "Default file not found" } unless File.exist?(default_path)
        
        begin
          data = JSON.parse(File.read(default_path, encoding: 'UTF-8'))
          
          # Salva no arquivo do usuário
          save_to_json(data)
          
          return data.merge({ success: true, message: "Default tags loaded" })
        rescue => e
          return { folders: [], tags: [], success: false, message: e.message }
        end
      end

      def self.load_from_file
        file_path = UI.openpanel("Selecionar arquivo JSON", "", "JSON Files|*.json||")
        return { folders: [], tags: [], success: false, message: "No file selected" } unless file_path
        
        begin
          data = JSON.parse(File.read(file_path, encoding: 'UTF-8'))
          unless data.is_a?(Hash) && data.key?("folders") && data.key?("tags")
            return { folders: [], tags: [], success: false, message: "Invalid JSON structure" }
          end
          return data.merge({ success: true, message: "Loaded from file" })
        rescue JSON::ParserError => e
          return { folders: [], tags: [], success: false, message: "Invalid JSON: #{e.message}" }
        rescue => e
          return { folders: [], tags: [], success: false, message: e.message }
        end
      end

      def self.import_layers(json_data)
        model = Sketchup.active_model
        return { success: false, message: "No model" } unless model
        
        model.start_operation("Import Tags", true)
        
        begin
          data = json_data.is_a?(String) ? JSON.parse(json_data) : json_data
          layers = model.layers
          created_count = 0
          
          label_layer = layers["2D-ETIQUETAS"] || layers.add("2D-ETIQUETAS")
          
          main_group = model.active_entities.add_group
          main_group.name = "REFERENCIAS_TAGS"
          main_group.layer = label_layer
          entidades = main_group.entities
          
          grupo_index = 0
          
          if data["folders"]
            data["folders"].each do |folder_data|
              folder = nil
              if layers.respond_to?(:folders)
                folder = layers.folders.find { |f| f.name == folder_data["name"] }
                folder ||= layers.add_folder(folder_data["name"])
              end
              
              camada_index = 0
              if folder_data["tags"]
                folder_data["tags"].each do |tag_data|
                  layer = layers[tag_data["name"]] || layers.add(tag_data["name"])
                  
                  if folder
                    begin
                      folder.add_layer(layer)
                    rescue; end
                  end
                  
                  if tag_data["color"]
                    color = tag_data["color"]
                    if color.is_a?(Array)
                        layer.color = Sketchup::Color.new(*color)
                    end
                  end
                  
                  create_visual_indicator(entidades, tag_data["name"], camada_index, grupo_index, layer)
                  camada_index += 1
                  created_count += 1
                end
              end
              grupo_index += 1
            end
          end
          
          camada_index = 0
          if data["tags"]
            data["tags"].each do |tag_data|
              layer = layers[tag_data["name"]] || layers.add(tag_data["name"])
              
              if tag_data["color"]
                 color = tag_data["color"]
                 if color.is_a?(Array)
                     layer.color = Sketchup::Color.new(*color)
                 end
              end

              create_visual_indicator(entidades, tag_data["name"], camada_index, grupo_index, layer)
              camada_index += 1
              created_count += 1
            end
          end
          
          model.commit_operation
          return { success: true, message: "#{created_count} tags imported", count: created_count }
        rescue => e
          model.abort_operation
          return { success: false, message: e.message }
        end
      end
      
      def self.create_visual_indicator(entities, name, layer_index, group_index, layer)
        size = 5.mm
        spacing = 5.mm
        
        x = (layer_index % 15) * spacing
        y = group_index * spacing * 2
        pt = Geom::Point3d.new(x, y, 0)
        
        square_pts = [
          pt,
          pt + Geom::Vector3d.new(size, 0, 0),
          pt + Geom::Vector3d.new(size, size, 0),
          pt + Geom::Vector3d.new(0, size, 0)
        ]
        
        face = entities.add_face(square_pts)
        if face
          face.layer = layer
          model = Sketchup.active_model
          mat_name = "MAT_#{name}".gsub(/[^a-zA-Z0-9_-]/, '_')
          material = model.materials[mat_name] || model.materials.add(mat_name)
          material.color = layer.color
          face.material = material
          face.back_material = material
        end
      rescue => e
        puts "Error creating visual indicator for '#{name}': #{e.message}"
      end

    end
  end
end