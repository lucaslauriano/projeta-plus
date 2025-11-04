# 📦 Build Scripts - Projeta Plus

Scripts para gerar builds de distribuição do plugin.

## 🚀 Uso Rápido

```bash
cd build/
./build_obfuscated.sh
```

No Windows (PowerShell):

```powershell
cd build
./build_obfuscated.ps1
```

O arquivo .rbz será criado em: `../dist/projeta_plus_obfuscated_v2.0.0.rbz`

---

## 📄 Arquivos

- **build_obfuscated.sh** - Gera build ofuscado (.rbz)
- **obfuscate.rb** - Ofuscador Ruby (chamado automaticamente)
- **clean_builds.sh** - Limpa arquivos temporários
- **BUILD_INSTRUCTIONS.md** - Documentação completa

---

## 🔧 Comandos

### Gerar build
```bash
./build_obfuscated.sh
```

Windows (PowerShell):

```powershell
./build_obfuscated.ps1
```

### Limpar temporários
```bash
./clean_builds.sh
```

### Ofuscar manualmente (opcional)
```bash
ruby obfuscate.rb
```

---

## 📋 O que o build faz

1. ✅ Ofusca código Ruby (remove comentários, minifica)
2. ✅ Preserva APIs públicas e callbacks
3. ✅ Copia componentes, ícones, traduções
4. ✅ Gera arquivo .rbz pronto para distribuir
5. ✅ Remove arquivos temporários automaticamente

---

## 📖 Documentação Completa

Veja: [BUILD_INSTRUCTIONS.md](./BUILD_INSTRUCTIONS.md)




