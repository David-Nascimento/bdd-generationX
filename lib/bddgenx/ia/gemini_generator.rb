# lib/bddgenx/cli.rb
# encoding: utf-8
#
# Este arquivo define a classe Runner (CLI) da gem bddgenx,
# responsável por orquestrar o fluxo de leitura de histórias,
# validação, geração de features, steps, backups e exportação de PDFs.
require 'dotenv/load'
require 'fileutils'
require_relative 'utils/parser'
require_relative 'generator'
require_relative 'utils/pdf_exporter'
require_relative 'steps_generator'
require_relative 'utils/validator'
require_relative 'utils/backup'
require_relative 'ia/gemini_cliente'
require_relative 'utils/gherkin_cleaner'
require_relative 'gemini_generator'

module Bddgenx
  # Ponto de entrada da gem: coordena todo o processo de geração BDD.
  class Runner
    def self.choose_files(input_dir)
      ARGV.any? ? selecionar_arquivos_txt(input_dir) : choose_input(input_dir)
    end

    def self.selecionar_arquivos_txt(input_dir)
      ARGV.map do |arg|
        nome = arg.end_with?('.txt') ? arg : "#{arg}.txt"
        path = File.join(input_dir, nome)
        unless File.exist?(path)
          warn "⚠️  Arquivo não encontrado: #{path}"
          next
        end
        path
      end.compact
    end

    def self.choose_input(input_dir)
      files = Dir.glob(File.join(input_dir, '*.txt'))
      if files.empty?
        warn "❌ Não há arquivos .txt no diretório #{input_dir}"; exit 1
      end

      puts "Selecione o arquivo de história para processar:"
      files.each_with_index { |f, i| puts "#{i+1}. #{File.basename(f)}" }
      print "Digite o número correspondente (ou ENTER para todos): "
      choice = STDIN.gets.chomp

      return files if choice.empty?
      idx = choice.to_i - 1
      unless idx.between?(0, files.size - 1)
        warn "❌ Escolha inválida."; exit 1
      end
      [files[idx]]
    end

    def self.execute
      modo = ENV['BDDGENX_MODE'] || 'static'

      input_dir = 'input'
      Dir.mkdir(input_dir) unless Dir.exist?(input_dir)

      arquivos = choose_files(input_dir)
      if arquivos.empty?
        warn "❌ Nenhum arquivo de história para processar."; exit 1
      end

      total = features = steps = ignored = 0
      skipped_steps = []
      generated_pdfs = []
      skipped_pdfs = []

      arquivos.each do |arquivo|
        total += 1
        puts "\n🔍 Processando: #{arquivo}"

        historia =
          if modo == 'gemini'
            puts "🤖 Gerando cenários com IA (Gemini)..."
            begin
              idioma = GeminiCliente.detecta_idioma_arquivo(arquivo)
              historia = File.read(arquivo)
              GeminiCliente.gerar_cenarios(historia, idioma)
            rescue => e
              ignored += 1
              puts "❌ Falha ao gerar com Gemini: #{e.message}"
              next
            end
          else
            historia = Parser.ler_historia(arquivo)
            unless Validator.validar(historia)
              ignored += 1
              puts "❌ História inválida: #{arquivo}"
              next
            end
            historia
          end

        historia_limpa = GherkinCleaner.limpar(historia_ia_gerada)
        feature_path, feature_content = Generator.gerar_feature(historia_limpa)

        Backup.salvar_versao_antiga(feature_path)
        features += 1 if Generator.salvar_feature(feature_path, feature_content)

        if StepsGenerator.gerar_passos(feature_path)
          steps += 1
        else
          skipped_steps << feature_path
        end

        FileUtils.mkdir_p('reports')
        result = PDFExporter.exportar_todos(only_new: true)
        generated_pdfs.concat(result[:generated])
        skipped_pdfs.concat(result[:skipped])
      end

      puts "\n✅ Processamento concluído"
      puts "- Total de histórias:    #{total}"
      puts "- Features geradas:      #{features}"
      puts "- Steps gerados:         #{steps}"
      puts "- Steps ignorados:       #{skipped_steps.size}"
      puts "- PDFs gerados:          #{generated_pdfs.size}"
      puts "- PDFs já existentes:    #{skipped_pdfs.size}"
      puts "- Histórias ignoradas:   #{ignored}"
    end
  end
end
