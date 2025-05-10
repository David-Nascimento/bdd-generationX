require_relative "bddgen/version"
require_relative "bddgen/cli"
require_relative "bddgen/parser"
require_relative "bddgen/validator"
require_relative "bddgen/generator"
require_relative "bddgen/steps_generator"
require_relative "bddgen/tracer"
require_relative "bddgen/backup"
require_relative 'bddgen/pdf_exporter'

cont_total = 0
cont_features = 0
cont_steps = 0
cont_ignorados = 0

# Exibe menu inicial e pergunta quais arquivos processar
arquivos = CLI.selecionar_arquivos_txt('input')

arquivos.each do |arquivo_path|
 puts "\n🔍 Processando: #{arquivo_path}"

  historia = Parser.ler_historia(arquivo_path)

  unless Validator.validar(historia)
    cont_ignorados += 1
    puts "❌ Arquivo inválido: #{arquivo_path}"
    next
  end

  nome_feature, conteudo_feature = Generator.gerar_feature(historia)

  Backup.salvar_versao_antiga(nome_feature)
  cont_features += 1 if Generator.salvar_feature(nome_feature, conteudo_feature)
  cont_steps += 1 if StepsGenerator.gerar_passos(historia, nome_feature)


  Tracer.adicionar_entrada(historia, nome_feature)
end

puts "\n✅ Processamento finalizado. Arquivos gerados em: features/, steps/, output/"
puts "🔄 Versões antigas salvas em: backup/"

puts "\n✅ Processamento finalizado:"
puts "- Arquivos processados: #{cont_total}"
puts "- Features geradas:     #{cont_features}"
puts "- Steps gerados:        #{cont_steps}"
puts "- Ignorados:            #{cont_ignorados}"
