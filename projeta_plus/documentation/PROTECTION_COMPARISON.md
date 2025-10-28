# 🔒 Comparação de Métodos de Proteção

## Resumo Rápido

| Método                | Segurança | Facilidade | Reversível | Compatibilidade |
| --------------------- | --------- | ---------- | ---------- | --------------- |
| **Nenhuma**           | ⚠️ 0/10   | ✅ 10/10   | ✅ 100%    | ✅ Tudo         |
| **Ofuscação Simples** | ⚠️ 3/10   | ✅ 8/10    | ⚠️ Fácil   | ✅ Ruby         |
| **.rbs (SketchUp)**   | ✅ 8/10   | ⚠️ 6/10    | ❌ Difícil | ⚠️ Só SketchUp  |

## 📊 Método 1: Código Aberto (Padrão)

### ✅ Vantagens

- Transparência e confiança dos usuários
- Fácil debug e contribuições da comunidade
- Aceito no Extension Warehouse
- Sem complexidade extra

### ❌ Desvantagens

- Código totalmente visível
- Fácil de copiar/modificar
- Sem proteção de IP

### 📝 Exemplo

```ruby
# projeta_plus/main.rb (visível)
module ProjetaPlus
  def self.create_annotation(text)
    entity = Sketchup.active_model.active_entities.add_text(text)
    entity
  end
end
```

### 🎯 Quando Usar

- Plugins gratuitos e open source
- Projetos educacionais
- Quando comunidade > proteção

---

## 🔐 Método 2: Ofuscação Simples (Base64 + Zlib)

### Como Funciona

```ruby
# Original
def calculate(a, b)
  a + b
end

# Ofuscado (comprimido e codificado)
require 'base64'; require 'zlib'
_c = "eJxLyslPzk9JVchNLErMKVHIyy9RKMnMS1coyVcoyUxOLVIAAPpODJI="
_d = Zlib::Inflate.inflate(Base64.strict_decode64(_c))
eval(_d)
```

### ✅ Vantagens

- Não precisa do SketchUp para gerar
- Rápido de implementar
- Funciona em qualquer Ruby

### ❌ Desvantagens

- **Segurança baixa**: Qualquer um pode decodificar
- Impacto leve na performance (eval)
- Dificulta debug

### 🛠️ Como Usar

```bash
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
ruby obfuscate_simple.rb
```

### 🎯 Quando Usar

- Proteção mínima contra usuários casuais
- Quando não pode usar .rbs
- Como camada adicional de proteção

---

## 🔒 Método 3: .rbs (Criptografia SketchUp)

### Como Funciona

O SketchUp tem uma função nativa que criptografa código Ruby em formato binário.

```ruby
# Original (main.rb)
module ProjetaPlus
  VERSION = "2.0.0"
end

# Criptografado (main.rbs) - BINÁRIO ILEGÍVEL
\x89\x50\x4E\x47\x0D\x0A\x1A\x0A...
```

### ✅ Vantagens

- **Segurança alta**: Muito difícil de reverter
- Método oficial do SketchUp
- Performance nativa (sem eval)
- Usado por plugins comerciais profissionais

### ❌ Desvantagens

- Precisa do SketchUp para gerar
- Mais complexo de configurar
- Debug muito difícil
- Irreversível (mantenha originais!)

### 🛠️ Como Usar

**Opção A: Manual**

```bash
# 1. Abrir SketchUp
# 2. Ruby Console
# 3. Colar:
load '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/encrypt_sketchup.rb'

# 4. Aguardar conclusão
# 5. Build:
./build_encrypted.sh
```

**Opção B: Automática (experimental)**

```bash
./auto_encrypt.sh
# Abre SketchUp e executa automaticamente via AppleScript
```

### 🎯 Quando Usar

- **Plugins comerciais**
- **Proteção séria de IP**
- Distribuição para clientes pagantes
- Quando segurança > conveniência

---

## 📈 Comparação Prática

### Exemplo: Função de Cálculo de Área

#### 1. Código Original (48 bytes)

```ruby
def calc_area(w, h)
  w * h
end
```

#### 2. Ofuscação Simples (156 bytes)

```ruby
require 'base64';require 'zlib';_c="eJxLyslPzk9J...";eval(Zlib::Inflate.inflate(Base64.strict_decode64(_c)))
```

**Resultado**: 3.25x maior, facilmente decodificável

#### 3. .rbs Criptografado (~52 bytes)

```
\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00...
```

**Resultado**: Tamanho similar, **ilegível e difícil de reverter**

---

## 🛡️ Recomendações por Cenário

### Cenário 1: Plugin Gratuito para Comunidade

```
✅ Código aberto (.rb normal)
```

- Build com `./build_simple.sh`
- Distribua no Extension Warehouse
- Ganhe reputação e feedback

### Cenário 2: Plugin Comercial de Baixo Valor ($0-20)

```
⚠️ Ofuscação simples OU .rbs
```

- Ofuscação já dificulta cópias casuais
- .rbs se quiser mais proteção
- Foque mais em licenciamento online

### Cenário 3: Plugin Comercial Premium ($50+)

```
🔒 .rbs + Licenciamento + Proteções Extras
```

- Sempre use .rbs
- Adicione verificação de licença online
- Implemente hardware fingerprinting
- Considere servidor de validação

### Cenário 4: Plugin Corporativo (B2B)

```
🔒 .rbs + Licenciamento Enterprise
```

- .rbs obrigatório
- Licenças por domínio/organização
- Telemetria de uso
- Contrato legal (EULA)

---

## 🔧 Proteções Complementares

### 1. Licenciamento Online

```ruby
module ProjetaPlus
  def self.verify_license
    require 'net/http'
    uri = URI('https://api.seusite.com/verify')
    response = Net::HTTP.post_form(uri, {
      'key' => read_license_key,
      'hwid' => get_hardware_id
    })
    JSON.parse(response.body)['valid']
  rescue
    false
  end
end
```

### 2. Hardware Fingerprint

```ruby
def get_hardware_id
  require 'digest'
  mac = `ifconfig | grep ether | head -n1`.strip
  Digest::SHA256.hexdigest(mac)[0..15]
end
```

### 3. Trial Período

```ruby
def check_trial
  install_date = Sketchup.read_default("ProjetaPlus", "install_date", nil)
  if install_date.nil?
    Sketchup.write_default("ProjetaPlus", "install_date", Time.now.to_i)
    return true
  end

  days_passed = (Time.now.to_i - install_date.to_i) / 86400
  days_passed <= 30 # 30 dias de trial
end
```

### 4. Domínio Whitelist (Corporativo)

```ruby
ALLOWED_DOMAINS = ['empresa.com', 'subsidiaria.com']

def check_domain
  hostname = `hostname`.strip
  ALLOWED_DOMAINS.any? { |d| hostname.end_with?(d) }
end
```

---

## 📊 Matriz de Decisão

```
Valor do Plugin:  Grátis   $1-20   $20-50   $50+   B2B
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Código aberto      ✅       ⚠️      ❌      ❌     ❌
Ofuscação simples  ⚠️       ✅      ⚠️      ❌     ❌
.rbs               ⚠️       ✅      ✅      ✅     ✅
Licença online     ❌       ⚠️      ✅      ✅     ✅
Hardware ID        ❌       ❌      ⚠️      ✅     ✅
EULA legal         ⚠️       ⚠️      ✅      ✅     ✅
```

---

## 💡 Dicas Finais

### ✅ Boas Práticas

1. **Sempre mantenha originais**: Git privado + backup externo
2. **Teste antes de distribuir**: Versão criptografada deve funcionar 100%
3. **Documente bem**: Código criptografado = debug difícil
4. **Combine métodos**: .rbs + licenciamento > apenas .rbs
5. **Seja transparente**: Informe aos usuários sobre proteção (no EULA)

### ❌ Não Faça

1. Não criptografe sem backup dos originais
2. Não confie 100% em proteção técnica (use contratos)
3. Não ofusque plugins gratuitos (perde confiança)
4. Não esqueça de testar versão criptografada
5. Não use proteção como desculpa para código ruim

### 🎯 Recomendação para Projeta Plus

**Se for distribuir gratuitamente:**

```bash
./build_simple.sh  # Código aberto
```

**Se for vender ($20-50):**

```bash
# 1. Criptografar
load 'encrypt_sketchup.rb'  # No SketchUp

# 2. Build
./build_encrypted.sh

# 3. Adicionar licenciamento online
```

**Se for enterprise/B2B:**

```
.rbs + Licença online + Hardware ID + EULA + Suporte
```

---

## 📚 Recursos Adicionais

- [SketchUp Extension Developer Center](https://extensions.sketchup.com/developer_center)
- [Ruby Code Obfuscation Best Practices](https://www.ruby-lang.org)
- [Software Licensing 101](https://choosealicense.com/)

## ✉️ Suporte

Dúvidas sobre qual método usar? Considere:

1. Qual o valor do seu plugin?
2. Quem é seu público (gratuito/pago)?
3. Quanto tempo quer investir em proteção?
4. Precisa de debug frequente?

**Regra de ouro**: Proteção proporcional ao valor comercial.
