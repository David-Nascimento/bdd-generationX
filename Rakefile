# Rakefile
# Tarefas para geração automática de BDD e relatórios com bddgenx

require 'rake'
require 'fileutils'
require 'bddgenx'

namespace :bddgenx do
  desc 'Gerar arquivos .feature, steps, rastreabilidade e backups'
  task :gerar, [:only_new, :input_dir] do |t, args|
    # Parâmetros: only_new (true/false), input_dir (pasta com .txt)
    args.with_defaults(only_new: 'false', input_dir: 'input')
    only_new = args.only_new == 'true'
    input_dir = args.input_dir

    files = FileList["#{input_dir}/*.txt"]
    if files.empty?
      puts "❌ Nenhum arquivo encontrado em \#{input_dir}"
      next
    end

    files.each do |file|
      puts "🔄 Processando história: \#{file}"
      historia = Bddgenx::Parser.ler_historia(file)
      next unless Bddgenx::Validator.validar(historia)

      feature_path, conteudo = Bddgenx::Generator.gerar_feature(historia)

      Bddgenx::Backup.salvar_versao_antiga(feature_path)
      Bddgenx::Generator.salvar_feature(feature_path, conteudo)

      Bddgenx::StepsGenerator.gerar_passos(feature_path)
      Bddgenx::Tracer.adicionar_entrada(historia, feature_path)
    end

    puts "✅ Geração concluída#{' (apenas novos)' if only_new}!"
  end

  desc 'Exportar todos os arquivos .feature para PDF'
  task :pdf do
    puts '📦 Exportando features para PDF...'
    result = Bddgenx::PDFExporter.exportar_todos
    puts "   Gerados: \#{result[:generated].size}, Pulados: \#{result[:skipped].size}"
  end

  desc 'Remover diretórios gerados (reports/ e features/)'
  task :clean do
    %w[reports features].each do |dir|
      FileUtils.rm_rf(dir)
      puts "🗑️  Diretório removido: \#{dir}"
    end
  end
end

task default: 'bddgenx:gerar'
