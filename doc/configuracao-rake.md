📁 1. Criar um Rakefile no projeto do usuário

Exemplo de Rakefile:
```ruby
require "bddgenx"
require "rake"

namespace :bddgenx do
  desc "Gera arquivos .feature e steps a partir de arquivos .txt na pasta input/"
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

▶️ 2. Executar com Rake
Depois que o Rakefile estiver configurado, execute:
```sh
rake bddgenx:gerar
```
