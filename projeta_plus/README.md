# 🚀 Projeta Plus - SketchUp Extension

Ferramenta completa para anotações arquitetônicas, ambientes, iluminação e gestão de projetos no SketchUp.

## ⚡ Quick Start

### Gerar .rbz Normal (5 segundos)

```bash
./build_simple.sh
# → dist/projeta_plus_v2.0.0.rbz
```

### Gerar .rbz Criptografado (Proteção de Código)

```bash
# 1. No SketchUp Ruby Console:
load 'encrypt_sketchup.rb'

# 2. No terminal:
./build_encrypted.sh
# → dist/projeta_plus_encrypted_v2.0.0.rbz
```

## 📚 Documentação Completa

**[Ver documentação completa →](documentation/)**

| Documento                                                       | Descrição                   |
| --------------------------------------------------------------- | --------------------------- |
| [Quick Start](documentation/QUICK_START.md)                     | ⚡ Guia rápido de 5 minutos |
| [Build Index](documentation/BUILD_INDEX.md)                     | 📍 Índice geral de builds   |
| [Encryption Guide](documentation/ENCRYPTION_GUIDE.md)           | 🔒 Como proteger o código   |
| [Protection Comparison](documentation/PROTECTION_COMPARISON.md) | 📊 Comparar métodos         |

## 🎯 Funcionalidades

- ✅ Anotação de ambientes
- ✅ Anotação de seção
- ✅ Anotação de teto
- ✅ Sistema de iluminação
- ✅ Conexão de circuitos elétricos
- ✅ Indicação de vistas
- ✅ Atualização automática de componentes
- ✅ Suporte multi-idioma (PT, EN, ES)

## 🛠️ Scripts Disponíveis

| Script                | Função                       |
| --------------------- | ---------------------------- |
| `build_simple.sh`     | Build rápido (código aberto) |
| `build_encrypted.sh`  | Build criptografado (.rbs)   |
| `encrypt_sketchup.rb` | Criptografar arquivos        |
| `obfuscate_simple.rb` | Ofuscação Base64             |
| `clean_builds.sh`     | Limpar temporários           |

## 📦 Estrutura do Projeto

```
projeta_plus/
├── README.md                    ← Você está aqui
├── documentation/               ← Documentação completa
├── build_simple.sh              ← Build rápido
├── build_encrypted.sh           ← Build protegido
├── projeta_plus.rb              ← Loader principal
├── main.rb                      ← Entry point
├── commands.rb                  ← Comandos
├── core.rb                      ← UI
├── modules/                     ← Funcionalidades
│   ├── annotation/
│   ├── settings/
│   └── view/
├── dialog_handlers/             ← Handlers
├── components/                  ← Componentes SketchUp
├── icons/                       ← Ícones
└── lang/                        ← Traduções (PT, EN, ES)
```

## 🚀 Instalação (Usuários)

1. Baixe o arquivo `.rbz`
2. Abra o SketchUp
3. **Window** > **Extension Manager**
4. Clique em **Install Extension**
5. Selecione o arquivo `.rbz`
6. Reinicie o SketchUp

## 👨‍💻 Desenvolvimento

### Testar no SketchUp

1. Copie a pasta `projeta_plus/` e o arquivo `projeta_plus.rb` para:
   ```
   ~/Library/Application Support/SketchUp 2025/SketchUp/Plugins/
   ```
2. Reinicie o SketchUp
3. O plugin aparecerá no menu **Plugins** > **PROJETA PLUS**

### Estrutura de Código

- **Ruby** com paradigma funcional
- **Módulos** separados por funcionalidade
- **Dialog Handlers** para comunicação JS ↔ Ruby
- **i18n** com arquivos YAML em `lang/`

## 🔐 Proteção de Código

Oferece 3 níveis de proteção:

| Método       | Segurança | Quando Usar         |
| ------------ | --------- | ------------------- |
| **Aberto**   | 0/10      | Grátis, open source |
| **Ofuscado** | 3/10      | Proteção básica     |
| **.rbs**     | 8/10      | Comercial, premium  |

[Ver comparação detalhada →](documentation/PROTECTION_COMPARISON.md)

## 📝 Licença

© 2025 Lucas Lauriano

## 🆘 Suporte

- 📖 [Documentação](documentation/)
- 🐛 Issues: [Link do repositório]
- 💬 Contato: [Seu email]

---

**Versão**: 2.0.0  
**Compatibilidade**: SketchUp 2019+  
**Idiomas**: Português, English, Español
