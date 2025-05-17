# lib/bddgenx/cli.rb
# encoding: utf-8
#
# Este arquivo define a classe Runner (CLI) da gem bddgenx,
# responsável por orquestrar o fluxo de leitura de histórias,
# validação, geração de features, steps, backups e exportação de PDFs.
require_relative '../../bddgenx'

module Bddgenx
  # Ponto de entrada da gem: coordena todo o processo de geração BDD.
  class Runner
    # Seleciona arquivos de entrada para processamento.
    # Se houver argumentos em ARGV, usa-os como nomes de arquivos .txt;
    # caso contrário, exibe prompt interativo para escolha.
    #
    # @param input_dir [String] Diretório onde estão os arquivos .txt de histórias
    # @return [Array<String>] Lista de caminhos para os arquivos a serem processados
    def self.choose_files(input_dir)
      ARGV.any? ? selecionar_arquivos_txt(input_dir) : choose_input(input_dir)
    end

    # Mapeia ARGV para paths de arquivos .txt em input_dir.
    # Adiciona extensão '.txt' se necessário e filtra arquivos inexistentes.
    #
    # @param input_dir [String] Diretório de entrada
    # @return [Array<String>] Caminhos válidos para processamento
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

    # Exibe prompt interativo para o usuário escolher qual arquivo processar
    # entre todos os .txt disponíveis em input_dir.
    #
    # @param input_dir [String] Diretório de entrada
    # @exit [1] Se nenhum arquivo for encontrado ou escolha inválida
    # @return [Array<String>] Um único arquivo escolhido ou todos se ENTER
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

    # Executa todo o fluxo de geração BDD.
    # - Cria pasta 'input' se não existir
    # - Seleciona arquivos de histórias
    # - Para cada arquivo:
    #   - Lê e valida a história
    #   - Gera arquivo .feature e salva backup da versão anterior
    #   - Gera definitions de steps
    #   - Exporta PDFs novos via PDFExporter
    # - Exibe resumo final com estatísticas
    #
    # @return [void]
    def self.execute
      modo = ENV['BDDGENX_MODE'] || 'static'

      input_dir = 'input'
      Dir.mkdir(input_dir) unless Dir.exist?(input_dir)

      arquivos = choose_files(input_dir)
      if arquivos.empty?
        warn "❌ Nenhum arquivo de história para processar."; exit 1
      end

      # Inicializa contadores
      total = features = steps = ignored = 0
      skipped_steps = []
      generated_pdfs = []
      skipped_pdfs = []

      arquivos.each do |arquivo|
        total += 1
        puts "\n🔍 Processando: #{arquivo}"

        historia = Parser.ler_historia(arquivo)
        unless Validator.validar(historia)
          ignored += 1
          puts "❌ História inválida: #{arquivo}"
          next
        end

        # Geração de feature
        if modo == 'gemini' || modo == 'chatgpt'
          puts "🤖 Gerando cenários com IA (#{modo.capitalize})..."
          idioma = IA::GeminiCliente.detecta_idioma_arquivo(arquivo)
          feature_text =
            if modo == 'gemini'
              IA::GeminiCliente.gerar_cenarios(historia, idioma)
            else
              IA::ChatGptCliente.gerar_cenarios(historia, idioma)
            end
          if feature_text
            feature_path = Generator.path_para_feature(arquivo)
            feature_content = Bddgenx::GherkinCleaner.limpar(feature_text)
          else
            ignored += 1
            puts "❌ Falha ao gerar com IA: #{arquivo}"
            next
          end
        else
          feature_path, feature_content = Generator.gerar_feature(historia)
        end

        Backup.salvar_versao_antiga(feature_path)
        features += 1 if Generator.salvar_feature(feature_path, feature_content)

        # Geração de steps
        if StepsGenerator.gerar_passos(feature_path)
          steps += 1
        else
          skipped_steps << feature_path
        end

        # Exportação de PDF (apenas novos)
        FileUtils.mkdir_p('reports')
        result = PDFExporter.exportar_todos(only_new: true)
        generated_pdfs.concat(result[:generated])
        skipped_pdfs.concat(result[:skipped])
      end

      # Exibe relatório final
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
