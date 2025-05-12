# 🧪 Gerador de BDD Automático em Ruby

Este projeto gera arquivos `.feature` (Gherkin) e `steps.rb` automaticamente a partir de arquivos `.txt` com histórias de usuário, seguindo padrões ISTQB, parametrização com `Examples` e integração com pipelines.

---

## 📂 Estrutura do Projeto
```txt
bddgenx/                      # raiz do repositório
├── bin/                      # executáveis CLI
│   └── bddgenx               # script que chama Bddgenx::Runner.executar
├── lib/                      # código-fonte da gem
│   ├── bddgenx/              # namespace principal
│   │   ├── parser.rb
│   │   ├── validator.rb
│   │   ├── generator.rb
│   │   ├── steps_generator.rb
│   │   ├── tracer.rb
│   │   ├── backup.rb
│   │   ├── pdf_exporter.rb
│   │   └── utils/             # helpers e módulos auxiliares
│   │       └── verificador.rb
│   └── bddgenx.rb            # entrypoint: require_relative de tudo
├── features/                 # specs Cucumber para testar a gem
│   └── support/              # support files para os testes
├── spec/ or test/            # unit tests (RSpec, Minitest)
├── input/                    # exemplos de .txt de usuários
├── output/                   # artefatos gerados (rastreabilidade.csv, etc.)
├── pdf/                      # PDFs gerados
├── backup/                   # backups automáticos
├── doc/                      # documentação (markdown)
│   ├── configuracao-padra.md
│   └── configuracao-rake.md
├── bddgenx.gemspec           # gemspec
├── Gemfile                   # dependências de desenvolvimento
├── Rakefile                  # tarefas: build, test, release, clean…
├── .gitignore
└── README.md                 # descrição, instalação, exemplos de uso

```
## ▶️ Como Executar

### 🔧 Requisitos
- Ruby 3.x
- `bundle install` (caso use gems como `prawn` ou `jira-ruby`)

### 🏁 Comando direto:

```bash
ruby main.rb
```

🧱 Com Rake:
```bash
rake bddgen:gerar
```

📥 Como Escrever um .txt de Entrada
```txt
# language: pt
Como um usuario do sistema
Quero fazer login com sucesso
Para acessar minha conta

[SUCCESS]@mobile
Quando preencho email e senha válidos
Então vejo a tela inicial

[SUCCESS]@regressivo
Quando tento logar com "<email>" e "<senha>"
Então recebo "<resultado>"

[EXAMPLES]
| email            | senha   | resultado               |
| user@site.com    | 123456  | login realizado         |
| errado@site.com  | senha   | credenciais inválidas   |
```
✅ Blocos Suportados
[CONTEXT] – contexto comum

[SUCCESS] – cenário positivo

[FAILURE] – cenário negativo

[ERROR], [EXCEPTION], [PERFORMANCE], etc.

[REGRA] ou [RULE] – regras de negócio

[EXAMPLES] – tabela de dados para Scenario Outline

🧠 Saída esperada (feature)
```gherkin
# language: pt
Funcionalidade: adicionar produtos ao carrinho

  Como um cliente do e-commerce
  Quero adicionar produtos ao carrinho
  Para finalizar minha compra com praticidade

  Regra: O carrinho não deve permitir produtos fora de estoque
    E o valor total deve refletir o desconto promocional

  Contexto:
    Dado que estou logado na plataforma
    E tenho produtos disponíveis

  @success
  Cenário: Teste Positivo - adiciono um produto ao carrinho - ele aparece na listagem do carrinho
    Quando adiciono um produto ao carrinho
    Então ele aparece na listagem do carrinho

  Esquema do Cenário: Gerado a partir de dados de exemplo
    Quando adiciono "<produto>" com quantidade <quantidade>
    Então vejo o total <total esperado>

    Exemplos:
      | produto        | quantidade | total esperado |
      | Camiseta Azul  | 2          | 100            |
      | Tênis Branco   | 1          | 250            |
```

🧩 Step Definitions geradas
```ruby
Quando('adiciono "<produto>" com quantidade <quantidade>') do |produto, quantidade|
  pending 'Implementar passo: adiciono "<produto>" com quantidade <quantidade>'
end

Então('vejo o total <total esperado>') do |total_esperado|
  pending 'Implementar passo: vejo o total <total esperado>'
end
```
🧾 Rastreabilidade
- Gera automaticamente um CSV em output/rastreabilidade.csv com:
- Nome do cenário
- Tipo (SUCCESS, FAILURE, etc.)
- Caminho do .feature
- Origem do .txt

🔄 Backup
Toda vez que um .feature existente for sobrescrito, a versão anterior é salva em:
```
backup/
```
✅ Execução em CI/CD (GitHub Actions)
```yaml
jobs:
  gerar_bdd:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
      - run: ruby main.rb
```
⚙️ Alternativa: Usar via Rake

Você também pode executar a gem bddgenx com Rake, como em projetos Rails:

Crie um arquivo Rakefile:
```ruby
require "bddgenx"
require "rake"

namespace :bddgenx do
  desc "Gera arquivos .feature e steps a partir de arquivos .txt"
  task :gerar do
    arquivos = Dir.glob("input/*.txt")

    arquivos.each do |arquivo|
      historia = Bddgenx::Parser.ler_historia(arquivo)
      next unless Bddgenx::Validator.validar(historia)

      nome_feature, conteudo = Bddgenx::Generator.gerar_feature(historia)
      Bddgenx::Backup.salvar_versao_antiga(nome_feature)
      Bddgenx::Generator.salvar_feature(nome_feature, conteudo)

      Bddgenx::StepsGenerator.gerar_passos(historia, nome_feature)
      Bddgenx::Tracer.adicionar_entrada(historia, nome_feature)
    end

    puts "✅ Geração BDD concluída com sucesso!"
  end
end

```

👨‍💻 Autor
David Nascimento – Projeto de automação BDD com Ruby – 2025
---