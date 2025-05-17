# Gerador Automático de BDD em Ruby
[![Gem Version](https://badge.fury.io/rb/bddgenx.svg)](https://badge.fury.io/rb/bddgenx)

## Visão Geral

Ferramenta Ruby para gerar automaticamente arquivos Gherkin (`.feature`) e definições de passos (`steps.rb`) a partir de histórias em texto. Atende aos padrões ISTQB, suporta parametrização com blocos de exemplos e fornece relatórios de QA (rastreabilidade, backups e PDF).

## Estrutura do projeto
```
bdd-generation/
├── .github/                     # Workflows do GitHub Actions
│   └── workflows/
│       └── main.yml
├── bin/
│   └── console                  # Execução local (se necessário)
├── features/                    # Gherkin gerados automaticamente
│   └── steps/                   # Steps correspondentes
├── input/                       # Histórias de entrada
│   ├── historia.txt
│   ├── historia_en.txt
│   └── ...
├── lib/
│   ├── bddgenx/
│   │   ├── generators/
│   │   │   ├── generator.rb       # Geração de arquivos .feature
│   │   │   ├── steps_generator.rb # Geração de arquivos de step
│   │   │   └── runner.rb          # Execução geral conforme modo (static/chatgpt/gemini)
│   │   ├── ia/
│   │   │   ├── chatgpt_cliente.rb # Cliente OpenAI
│   │   │   └── gemini_cliente.rb  # Cliente Gemini
│   │   ├── reports/
│   │   │   ├── backup.rb
│   │   │   ├── pdf_exporter.rb
│   │   │   └── tracer.rb
│   │   ├── support/
│   │   │   ├── font_loader.rb
│   │   │   ├── gherkin_cleaner.rb
│   │   │   ├── remover_steps_duplicados.rb
│   │   │   └── validator.rb
│   │   ├── configuration.rb       # Configuração global da gem (modo, vars de ambiente)
│   │   └── version.rb             # Carrega versão a partir do arquivo VERSION
│   ├── bddgenx.rb                 # Ponto de entrada da gem (requer env)
│   └── parser.rb                  # Parser de arquivos de entrada
├── reports/                     # Saídas: PDF, backup, rastreabilidade
│   ├── pdf/
│   ├── backup/
│   └── rastreabilidade/
├── .env                         # Variáveis de ambiente
├── .gitignore
├── bddgenx.gemspec
├── bump_version.sh
├── Gemfile
├── Gemfile.lock
├── LICENSE
├── Rakefile
├── README.md
└── VERSION
```
## Instalação

Adicione ao seu `Gemfile`:

```ruby
gem 'bddgenx'
```

Execute:

```bash
bundle install
```

Ou instale diretamente:

```bash
gem install bddgenx
```

## Uso no Código

```ruby
require 'bddgenx'

require 'bddgenx'

# Configuração
Bddgenx.configure do |config|
  config.mode = :chatgpt  # :static, :chatgpt ou :gemini
  config.openai_api_key_env = 'OPENAI_API_KEY'
end

# Executar geração
Bddgenx::Runner.execute('Minha história de exemplo', idioma: 'pt')
```

## Tarefa Rake (opcional)

Em um projeto Rails ou Ruby com Rake, adicione ao `Rakefile`:

```ruby
require_relative 'lib/env'
require 'rake'
require 'bddgenx'

namespace :bddgenx do
  desc 'Executa a geração BDD usando o modo atual (static, chatgpt, gemini)'
  task :generate do
    puts "⚙️  Modo de geração: #{Bddgenx.configuration.mode}"
    Bddgenx::Runner.execute
  end

  desc 'Gera features no modo estático (sem IA)'
  task :static do
    Bddgenx.configure do |config|
      config.mode = :static
    end
    ENV['BDDGENX_MODE'] = 'static'
    Rake::Task['bddgenx:generate'].invoke
  end

  desc 'Gera features usando ChatGPT'
  task :chatgpt do
    Bddgenx.configure do |config|
      config.mode = :chatgpt
      config.openai_api_key_env = 'OPENAI_API_KEY'
    end
    ENV['BDDGENX_MODE'] = 'chatgpt'
    Rake::Task['bddgenx:generate'].invoke
  end

  desc 'Gera features usando Gemini'
  task :gemini do
    Bddgenx.configure do |config|
      config.mode = :gemini
      config.gemini_api_key_env = 'GEMINI_API_KEY'
    end
    ENV['BDDGENX_MODE'] = 'gemini'
    Rake::Task['bddgenx:generate'].invoke
  end
end
```

## Formato do Arquivo de Entrada (`.txt`)

```txt
# language: pt
Como um usuário do sistema
Quero fazer login
Para acessar minha conta

[SUCCESS]
Quando preencho <email> e <senha>
Então vejo a tela inicial

[EXAMPLES]
| email            | senha   | resultado               |
| user@site.com    | 123456  | login realizado         |
| errado@site.com  | senha   | credenciais inválidas   |
```

## Artefatos de QA

* **Backup**: versões antigas de `.feature` em `reports/backup` com timestamp
* **PDF**: exporta features em P/B para `reports/pdf` via `PDFExporter`

## Integração CI/CD

Exemplo de GitHub Actions:

```yaml
jobs:
  gerar_bdd:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.x'
      - run: bundle install
      - run: bundle exec ruby -e "require 'bddgenx'; Bddgenx::Runner.execute(only_new: true)"
```

## Licença

MIT © 2025 David Nascimento
