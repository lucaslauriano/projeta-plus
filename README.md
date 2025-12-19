# 🚀 Projeta Plus - SketchUp Extension

Plugin premium para anotações arquitetônicas, ambientes, iluminação e gestão de projetos no SketchUp.

**Valor:** R$ 350,00/ano  
**Licenciamento:** Clerk + Stripe (front-end)  
**Proteção:** .rbs (criptografia oficial SketchUp)

---

## ⚡ Build Profissional (Criptografado)

**[📖 Ver guia completo passo a passo →](documentation/STEP_BY_STEP.md)**

### Comandos Rápidos

```bash
# 1️⃣ Criptografar (no SketchUp Ruby Console):
load '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/encrypt_sketchup.rb'

# 2️⃣ Gerar .rbz (no terminal):
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
./build_encrypted.sh

# Resultado: dist/projeta_plus_encrypted_v2.0.0.rbz
```

---

## 🎯 Funcionalidades

- ✅ Anotação de ambientes
- ✅ Anotação de seção
- ✅ Anotação de teto (altura de pé-direito)
- ✅ Sistema de iluminação
- ✅ Conexão de circuitos elétricos
- ✅ Indicação de vistas
- ✅ Atualização automática de componentes
- ✅ Suporte multi-idioma (PT, EN, ES)

---

## 📦 Estrutura do Projeto

```
projeta_plus/
├── README.md                      ← Você está aqui
├── documentation/
│   └── STEP_BY_STEP.md            ← Guia de build
│
├── encrypt_sketchup.rb            ← Criptografa → .rbs
├── build_encrypted.sh             ← Gera .rbz criptografado
├── clean_builds.sh                ← Limpa temporários
│
├── projeta_plus.rb                ← Loader principal
├── main.rb                        ← Entry point
├── commands.rb                    ← Comandos
├── core.rb                        ← UI
├── localization.rb                ← i18n
│
├── modules/                       ← Funcionalidades
│   ├── annotation/
│   │   ├── pro_room_annotation.rb
│   │   ├── pro_section_annotation.rb
│   │   ├── pro_ceiling_annotation.rb
│   │   ├── pro_eletrical_annotation.rb
│   │   ├── pro_lighting_annotation.rb
│   │   ├── pro_circuit_connection.rb
│   │   ├── pro_view_annotation.rb
│   │   └── pro_component_updater.rb
│   ├── settings/
│   │   ├── pro_settings.rb
│   │   └── pro_settings_utils.rb
│   └── pro_hover_face_util.rb
│
├── dialog_handlers/               ← Handlers JS ↔ Ruby
│   ├── base_handler.rb
│   ├── annotation_handler.rb
│   ├── settings_handler.rb
│   ├── model_handler.rb
│   └── extension_handler.rb
│
├── components/                    ← Componentes SketchUp
├── icons/                         ← Ícones
└── lang/                          ← Traduções (PT, EN, ES)
```

---

## 🔐 Proteção de Código

**Método:** `.rbs` (criptografia oficial SketchUp)  
**Segurança:** 8/10 (muito difícil de reverter)

### O que é protegido:

- ✅ Todo código Ruby (lógica, algoritmos, regras de negócio)
- ✅ Estrutura e arquitetura do plugin

### O que NÃO é protegido:

- ⚠️ Recursos (ícones, componentes .skp)
- ⚠️ Traduções (YAML)
- ⚠️ Front-end (HTML/CSS/JS) - minifique antes

**Importante:** `.rbs` não altera a API. Front-end continua chamando Ruby normalmente via `HtmlDialog` callbacks.

---

## 🛠️ Desenvolvimento

### Testar localmente

1. Código está em: `~/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus`
2. Reinicie o SketchUp
3. Menu: **Plugins** > **PROJETA PLUS**

### Estrutura de código

- **Ruby** com paradigma funcional
- **Módulos** separados por funcionalidade
- **Dialog Handlers** para comunicação JS ↔ Ruby
- **i18n** com arquivos YAML

---

## 📝 Versão & Licença

**Versão:** 2.0.0  
**Compatibilidade:** SketchUp 2019+  
**Idiomas:** Português, English, Español  
**Licença:** Proprietária - © 2025 Lucas Lauriano

---

## 📚 Documentação

- **[Guia de Build Criptografado](documentation/STEP_BY_STEP.md)** - Como gerar o .rbz profissional

---

## 🆘 Suporte

- 📖 Documentação completa em `documentation/`
- 🐛 Issues: [Link do repositório]
- 💬 Contato: [Seu email/suporte]

---

**Desenvolvido para profissionais de arquitetura que buscam produtividade no SketchUp.** 🏗️✨
