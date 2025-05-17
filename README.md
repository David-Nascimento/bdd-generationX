# Gerador Automático de BDD em Ruby
[![Gem Version](https://badge.fury.io/rb/bddgenx.svg)](https://badge.fury.io/rb/bddgenx)

## Visão Geral

Ferramenta Ruby para gerar automaticamente arquivos Gherkin (`.feature`) e definições de passos (`steps.rb`) a partir de histórias em texto. Atende aos padrões ISTQB, suporta parametrização com blocos de exemplos e fornece relatórios de QA (rastreabilidade, backups e PDF). Também suporta geração via IA (OpenAI / Gemini) e configuração por ambiente.

---

## Estrutura do Projeto

```
bdd-generation/
├── .github/                       # Workflows de CI/CD
│   └── workflows/
│       └── main.yml               # Workflow de build/test
├── bin/                           # Scripts CLI e de configuração
│   ├── bddgenx                    # Executável CLI para gerar BDD (static/chatgpt/gemini)
│   └── setup.rb                   # Script para preparar o ambiente local (gera .env, input/)
├── features/                      # Gherkin gerados automaticamente
│   └── steps/                     # Steps correspondentes aos cenários
├── input/                         # Arquivos de entrada (.txt com histórias)
│   ├── historia.txt
│   ├── historia_en.txt
│   └── ...
├── lib/
│   ├── bddgenx/
│   │   ├── generators/            # Lógica de geração de features e execução geral
│   │   │   ├── generator.rb
│   │   │   ├── steps_generator.rb
│   │   │   └── runner.rb
│   │   │
│   │   ├── ia/                    # Integração com APIs de IA
│   │   │   ├── chatgpt_cliente.rb
│   │   │   └── gemini_cliente.rb
│   │   │
│   │   ├── reports/               # Exportação de artefatos QA
│   │   │   ├── backup.rb
│   │   │   ├── pdf_exporter.rb
│   │   │   └── tracer.rb
│   │   │
│   │   ├── support/               # Utilitários auxiliares e validadores
│   │   │   ├── font_loader.rb
│   │   │   ├── gherkin_cleaner.rb
│   │   │   ├── remover_steps_duplicados.rb
│   │   │   └── validator.rb
│   │   │
│   │   ├── configuration.rb       # Configuração global da gem (modo, ENV keys)
│   │   └── version.rb             # Leitura da versão a partir do arquivo VERSION
│   │
│   ├── bddgenx.rb                 # Entrada principal da gem (require env)
│   └── parser.rb                  # Parser de arquivos de entrada
├── reports/                       # Artefatos gerados
│   ├── pdf/                       # Features exportadas em PDF
│   ├── backup/                    # Versões antigas de features
│   └── rastreabilidade/           # Arquivos de rastreabilidade (se implementado)
├── spec/                          # Testes unitários RSpec
│   ├── support/
│   ├── utils/
│   ├── ia/
│   ├── spec_helper.rb
│   └── version_spec.rb
├── .env                           # Arquivo com chaves reais (não versionado)
├── .env.example                   # Modelo para configurar variáveis de ambiente
├── .gitignore                     # Arquivos/pastas ignoradas pelo Git
├── bddgenx.gemspec                # Especificação da gem
├── bump_version.sh               # Script de versionamento automático (semântico)
├── Gemfile
├── Gemfile.lock
├── LICENSE
├── Rakefile                       # Tarefas automatizadas (static, chatgpt, gemini)
├── README.md                      # Documentação principal do projeto
└── VERSION                        # Arquivo contendo a versão atual da gem

```

---

## Instalação

Adicione ao seu `Gemfile`:

```ruby
gem 'bddgenx'
```

Ou instale diretamente:

```bash
gem install bddgenx
```

---

## 🔧 Configuração

### 1. Instale dependências

```bash
bundle install
```

### 2. Configure seu `.env`

```bash
cp .env.example .env
```

Edite o `.env`:

```env
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=ya29-...
BDDGENX_MODE=chatgpt   # static | chatgpt | gemini
```

> 🔐 Dica: nunca versionar o `.env` — ele já está no `.gitignore`

---

## 🚀 Uso com Rake

Com os arquivos `.txt` dentro da pasta `input/`, execute:

```bash
rake bddgenx:static     # geração sem IA
rake bddgenx:chatgpt    # usando ChatGPT
rake bddgenx:gemini     # usando Gemini
```

> O modo pode ser sobrescrito via ENV ou `Bddgenx.configure`

---

## 📦 Geração manual via Ruby

```ruby
require 'bddgenx'

Bddgenx.configure do |config|
  config.mode = :chatgpt
  config.openai_api_key_env = 'OPENAI_API_KEY'
end

Bddgenx::Runner.execute
```

---

## 📦 Geração manual via Rake
```Ruby
require_relative 'lib/env' # ajuste conforme seu projeto
require 'rake'

namespace :bddgenx do
  desc 'Gera arquivos BDD com IA ou modo estático. Use: rake bddgenx:generate[modo]'
  task :generate, [:modo] do |_, args|
    modo = args[:modo]&.downcase&.to_sym || :static

    unless %i[static chatgpt gemini deepseek].include?(modo)
      puts "❌ Modo inválido: #{modo}"
      puts "Use: rake bddgenx:generate[static|chatgpt|gemini|deepseek]"
      exit 1
    end

    Bddgenx.configure do |config|
      config.mode = modo
      config.openai_api_key_env = 'OPENAI_API_KEY'
      config.gemini_api_key_env = 'GEMINI_API_KEY'
      config.deepseek_api_key_env = 'DEEPSEEK_API_KEY'
    end

    ENV['BDDGENX_MODE'] = modo.to_s

    puts "⚙️  Gerando com modo: #{modo}"
    Bddgenx::Runner.execute
  end
end

```

## 📝 Formato do Arquivo de Entrada (`.txt`)

```txt
# language: pt
Como um usuário do sistema
Quero fazer login
Para acessar minha conta

[SUCCESS]
Quando preencho <email> e <senha>
Então vejo a tela inicial

[EXAMPLES]
| email            | senha   |
| user@site.com    | 123456  |
| errado@site.com  | senha   |
```

---

## 🧪 Setup Rápido para Novos Usuários

```bash
ruby bin/setup.rb
```

Esse comando:

- Cria `.env` a partir de `.env.example`
- Garante que `input/` existe

---

## 🧾 Artefatos Gerados

- ✅ `.feature` → dentro de `features/`
- ✅ `steps.rb` → dentro de `features/steps/`
- 🗂️ Backup automático → `reports/backup/`
- 📄 PDF das features → `reports/pdf/`

---

## ⚙️ CI/CD Exemplo com GitHub Actions

```yaml
jobs:
  gerar_bdd:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
      - run: bundle install
      - run: bundle exec rake bddgenx:chatgpt
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

---

## Licença

MIT © 2025 David Nascimento
