# Gerador Automático de BDD em Ruby

[![Gem Version](https://badge.fury.io/rb/bddgenx.svg)](https://badge.fury.io/rb/bddgenx)

## Visão Geral

Ferramenta Ruby para gerar automaticamente arquivos Gherkin (`.feature`) e definições de passos (`steps.rb`) a partir de histórias em texto. Atende aos padrões ISTQB, suporta parametrização com blocos de exemplos e fornece relatórios de QA (rastreabilidade, backups e PDF).

## Estrutura do Projeto

```
bdd-generation/
├── bin/
├── features/                    # Gherkin gerados automaticamente
│   └── steps/                   # Steps correspondentes
├── input/                       # Histórias de entrada
├── lib/
│   ├── bddgenx/
│   │   ├── generators/          # Geração de features e steps
│   │   ├── ia/                  # Integração com APIs de IA
│   │   ├── reports/             # Exportação PDF, backup, rastreio
│   │   ├── support/             # Validação e utilitários
│   │   ├── configuration.rb     # Configuração global
│   │   ├── setup.rb             # Cria estrutura inicial do projeto
│   │   └── version.rb           # Versão da gem
│   ├── bddgenx.rb
│   └── parser.rb
├── reports/
│   ├── backup/
│   ├── pdf/
│   └── rastreabilidade/
├── .env                         # Variáveis de ambiente
├── bddgenx.gemspec
├── Rakefile
└── README.md
```

## Instalação

Adicione ao seu `Gemfile`:

```ruby
gem 'bddgenx'
```

Instale com:

```bash
bundle install
```

Ou diretamente:

```bash
gem install bddgenx
```

## Inicialização do Projeto (`Setup.run`)

Antes de usar a gem, é recomendado executar o setup para criar:

* Pastas obrigatórias (`input/`, `features/steps/`, `reports/`...)
* Arquivo `historia.txt` com conteúdo exemplo
* Feature `.feature` e steps `_steps.rb`
* Arquivo `.env` com variáveis de ambiente

### Via Ruby

```bash
bundle exec ruby -e "require 'bddgenx'; Bddgenx::Setup.run"
```

### Via Rakefile

```ruby
require 'bddgenx'

namespace :bddgenx do
  desc 'Inicializa estrutura do projeto'
  task :setup do
    Bddgenx::Setup.run
  end
end
```

```bash
rake bddgenx:setup
```

## Configuração do `.env`

```dotenv
# OPENAI e GEMINI só são usados se modo for IA\OPENAI_API_KEY=xxx
GEMINI_API_KEY=xxx

BDDGENX_MODE=static    # static, chatgpt, gemini, deepseek
BDDGENX_LANG=pt        # pt ou en
```

## Uso via Código Ruby

```ruby
require 'bddgenx'

Bddgenx.configure do |config|
  config.mode = :gemini
  config.gemini_api_key_env = 'GEMINI_API_KEY'
end

Bddgenx::Runner.execute
```

## Uso via Rake

```ruby
require 'rake'
require 'bddgenx'

namespace :bddgenx do
  desc 'Executa geração interativa: escolha entre static, chatgpt, gemini ou deepseek'
  task :generate do
    puts "=== Qual modo deseja usar para gerar os cenários? ==="
    puts "1. static (sem IA)"
    puts "2. chatgpt (via OpenAI)"
    puts "3. gemini (via Google)"
    print "Digite o número (1-3): "

    escolha = STDIN.gets.chomp.to_i

    modo = case escolha
           when 1 then :static
           when 2 then :chatgpt
           when 3 then :gemini
           else
             puts "❌ Opção inválida. Saindo."; exit 1
           end

    Bddgenx.configure do |config|
      config.mode = modo
      config.openai_api_key_env = 'OPENAI_API_KEY'
      config.gemini_api_key_env = 'GEMINI_API_KEY'
    end

    # ⚠️ Limpa o ARGV antes de executar para evitar que [static] seja interpretado como nome de arquivo
    ARGV.clear

    ENV['BDDGENX_MODE'] = modo.to_s
    puts "\n⚙️  Modo selecionado: #{modo}\n\n"
    Bddgenx::Runner.execute
  end
end
```

Execute com:

```bash
rake bddgenx:generate[static]     # ou chatgpt, gemini, deepseek
```

## Formato do Arquivo de Entrada

```txt
# language: pt
Como um usuário do sistema
Quero acessar minha conta
Para realizar tarefas

[CONTEXT]
Dado que estou na tela de login

[SUCCESS]
Quando preencho email e senha
Então vejo a tela inicial

[EXAMPLES]
| email         | senha  | resultado          |
| user@site.com | 123456 | login realizado    |
| errado@site   | 000000 | credenciais inválidas |
```

## Geração de Artefatos

* Arquivos `.feature` na pasta `features/`
* Arquivos `*_steps.rb` na pasta `features/steps/`
* Arquivos PDF em `reports/pdf/`
* Backups de features anteriores em `reports/backup/`

## Licença

MIT © 2025 David Nascimento
