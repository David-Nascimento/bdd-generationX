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
│   └── bddgenx/
│       ├── ia/                  # Módulo de IA
│       │   ├── chatgpt_cliente.rb
│       │   └── gemini_cliente.rb
│       ├── generators/          # Responsável por geração
│       │   ├── generator.rb
│       │   ├── steps_generator.rb
│       │   └── runner.rb
│       ├── reports/            # Exportadores, backups e rastreabilidade
│       │   ├── pdf_exporter.rb
│       │   ├── backup.rb
│       │   └── tracer.rb
│       ├── support/            # Utilitários auxiliares
│       │   ├── gherkin_cleaner.rb
│       │   ├── remover_steps_duplicados.rb
│       │   ├── validator.rb
│       │   └── font_loader.rb
│       ├── parser.rb           # Parse do .txt
│       ├── version.rb          # Versão da gem
│       └── bddgenx.rb          # Arquivo principal (require central)
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

# Gera todas as features e steps a partir dos .txt em input/
Bddgenx::Runner.execute
```

## Tarefa Rake (opcional)

Em um projeto Rails ou Ruby com Rake, adicione ao `Rakefile`:

```ruby
require 'bddgenx'
require 'rake'

namespace :bddgenx do
  desc 'Gera .feature e steps a partir de histórias em input/'
  task :gerar do
    Bddgenx::Runner.execute
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
