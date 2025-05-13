require_relative 'bddgenx/parser'
require_relative 'bddgenx/validator'
require_relative 'bddgenx/generator'
require_relative 'bddgenx/steps_generator'
require_relative 'bddgenx/tracer'
require_relative 'bddgenx/backup'
require_relative 'bddgenx/cli'
require_relative 'bddgenx/pdf_exporter'
require_relative 'bddgenx/utils/verificador'

cont_total     = 0
cont_features  = 0
cont_steps     = 0
cont_ignorados = 0

# Seleciona arquivos .txt
arquivos = Bddgenx::Cli.selecionar_arquivos_txt('input')
# Antes do loop
skipped_steps = []
skipped_pdfs  = []
generated_pdfs = []
arquivos.each do |arquivo_path|
  cont_total += 1
  puts "\n🔍 Processando: #{arquivo_path}"

  historia = Bddgenx::Parser.ler_historia(arquivo_path)
  unless Bddgenx::Validator.validar(historia)
    cont_ignorados += 1
    puts "❌ Arquivo inválido: #{arquivo_path}"
    next
  end

  # Gera feature e steps
  nome_feature, conteudo_feature = Bddgenx::Generator.gerar_feature(historia)
  Bddgenx::Backup.salvar_versao_antiga(nome_feature)
  cont_features += 1 if Bddgenx::Generator.salvar_feature(nome_feature, conteudo_feature)
  cont_steps    += 1 if Bddgenx::StepsGenerator.gerar_passos(historia, nome_feature)

  # Rastreabilidade, PDF
  FileUtils.mkdir_p('reports')
  # steps
  if Bddgenx::StepsGenerator.gerar_passos(historia, nome_feature)
    cont_steps += 1
  else
    skipped_steps << nome_feature
  end
  # substituir chamada direta por:
  results = Bddgenx::PDFExporter.exportar_todos(only_new: true)
  # exportar_todos agora fornece [:generated, :skipped]
  generated_pdfs.concat(results[:generated])
  skipped_pdfs.concat(results[:skipped])
end

puts "\n✅ Processamento finalizado."
puts "- Features geradas:     #{cont_features}"
puts "- Steps gerados:        #{cont_steps}"
puts "- Steps mantidos:       #{skipped_steps.size}"
puts "- PDFs gerados:         #{generated_pdfs.size}"
puts "- PDFs já existentes:   #{skipped_pdfs.size}"
