# 📚 Documentação - Projeta Plus

Bem-vindo à documentação completa do Projeta Plus!

## 🚀 Começar Rápido

**Novo aqui?** → Comece com **[QUICK_START.md](QUICK_START.md)**

**Quer ver tudo?** → Veja o **[BUILD_INDEX.md](BUILD_INDEX.md)**

---

## 📖 Guias Disponíveis

### 🎯 Essenciais

| Arquivo                                                  | Descrição               | Leia se...              |
| -------------------------------------------------------- | ----------------------- | ----------------------- |
| **[QUICK_START.md](QUICK_START.md)**                     | ⚡ Guia rápido (5 min)  | Quer gerar .rbz agora   |
| **[BUILD_INDEX.md](BUILD_INDEX.md)**                     | 📍 Índice completo      | Quer visão geral        |
| **[PROTECTION_COMPARISON.md](PROTECTION_COMPARISON.md)** | 📊 Comparação detalhada | Decidindo como proteger |

### 🛠️ Build e Distribuição

| Arquivo                                                | Descrição             | Leia se...               |
| ------------------------------------------------------ | --------------------- | ------------------------ |
| **[BUILD_README.md](BUILD_README.md)**                 | Build normal (.rb)    | Distribuir código aberto |
| **[ENCRYPTION_GUIDE.md](ENCRYPTION_GUIDE.md)**         | Criptografia (.rbs)   | Proteger código          |
| **[PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)** | Checklist de produção | Pronto para distribuir   |

### 🎨 Melhorias

| Arquivo                                                      | Descrição           | Leia se...              |
| ------------------------------------------------------------ | ------------------- | ----------------------- |
| **[PRODUCTION_IMPROVEMENTS.md](PRODUCTION_IMPROVEMENTS.md)** | Melhorias de código | Quer código de produção |

---

## 🎯 Fluxograma de Leitura

```
1. QUICK_START.md
   ↓
2. Decidir: Grátis ou Pago?
   ├─ Grátis → BUILD_README.md
   └─ Pago → ENCRYPTION_GUIDE.md
   ↓
3. PRODUCTION_CHECKLIST.md
   ↓
4. Distribuir! 🚀
```

---

## 📁 Estrutura de Arquivos

```
projeta_plus/
├── documentation/                    ← VOCÊ ESTÁ AQUI
│   ├── README.md                     ← Índice da documentação
│   ├── BUILD_INDEX.md                ← Índice geral
│   ├── QUICK_START.md                ← START AQUI
│   ├── BUILD_README.md               ← Builds normais
│   ├── ENCRYPTION_GUIDE.md           ← Criptografia
│   ├── PROTECTION_COMPARISON.md      ← Comparação
│   ├── PRODUCTION_CHECKLIST.md       ← Checklist
│   └── PRODUCTION_IMPROVEMENTS.md    ← Melhorias
│
├── build_simple.sh                   ← Script de build
├── build_encrypted.sh                ← Build criptografado
├── encrypt_sketchup.rb               ← Criptografar
└── ...
```

---

## 💡 Dica Rápida

**Para 90% dos casos**:

```bash
cd ..
./build_simple.sh
# Pronto! → dist/projeta_plus_v2.0.0.rbz
```

**Para proteção comercial**:

```bash
# 1. No SketchUp Ruby Console:
load 'encrypt_sketchup.rb'

# 2. No terminal:
cd ..
./build_encrypted.sh
```

---

**Feito com ❤️ para facilitar o desenvolvimento do Projeta Plus**
