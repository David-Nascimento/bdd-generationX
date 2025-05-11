🚀 Como usar a gem bddgenx em um projeto real

📦 1. Instale a gem

Adicione ao seu Gemfile:
```ruby
gem "bddgenx"
```
Ou instale direto via terminal:
```sh
gem install bddgenx
```

📁 2. Crie um diretório de entrada com arquivos .txt
```sh
mkdir input
```

Exemplo de input/login.txt:
```txt
# language: pt
Como um usuário do sistema
Quero fazer login com sucesso
Para acessar minha conta

[CONTEXT]
Dado que estou na tela de login

[SUCCESS]
Quando preencho email e senha válidos
Então vejo a tela inicial

[EXAMPLES]
| email            | senha   | resultado esperado      |
| user@site.com    | 123456  | login realizado         |
| errado@site.com  | senha   | credenciais inválidas   |

[SUCCESS]
Quando tento logar com "<email>" e "<senha>"
Então recebo <resultado esperado>
```

🧠 3. Crie um script para executar a gem
```ruby
require 'bddgenx'

arquivos = Dir.glob('input/*.txt')
arquivos.each do |arquivo|
  historia = Bddgenx::Parser.ler_historia(arquivo)
  next unless Bddgenx::Validator.validar(historia)

  nome_feature, conteudo = Bddgenx::Generator.gerar_feature(historia)
  Bddgenx::Backup.salvar_versao_antiga(nome_feature)
  Bddgenx::Generator.salvar_feature(nome_feature, conteudo)

  Bddgenx::StepsGenerator.gerar_passos(historia, nome_feature)
  Bddgenx::Tracer.adicionar_entrada(historia, nome_feature)
end

puts "✅ Arquivos BDD gerados com sucesso!"
```

▶️ 4. Execute seu projeto
```sh
ruby gerar_bdd.rb
```

📂 5. Resultado esperado
Após a execução, você terá:

- features/login.feature — arquivo Gherkin pronto
- steps/login_steps.rb — definições de step com parâmetros {string} e {int}
- output/rastreabilidade.csv — rastreabilidade de origem

🧪 6. (Opcional) Execute com Cucumber
Se quiser usar os arquivos gerados em seus testes:
```sh
cucumber features/
```

