# lib/bddgenx/cli.rb
# encoding: utf-8
#
# Este arquivo define a classe Runner (CLI) da gem bddgenx,
# responsável por orquestrar todo o fluxo de geração BDD:
# leitura e validação de histórias, geração de features, steps,
# exportação de PDFs e controle de modo (static / IA).

require_relative '../../bddgenx'

module Bddgenx
  # Classe principal de execução da gem.
  # Atua como ponto de entrada (CLI) para processar arquivos de entrada
  # e gerar todos os artefatos BDD relacionados.
  class Runner

    ##
    # Retorna a lista de arquivos de entrada.
    # Se houver argumentos em ARGV, utiliza-os como nomes de arquivos `.txt`.
    # Caso contrário, chama prompt interativo.
    #
    # @param input_dir [String] Caminho do diretório de entrada
    # @return [Array<String>] Lista de arquivos `.txt` a processar
    def self.choose_files(input_dir)
      ARGV.any? ? selecionar_arquivos_txt(input_dir) : choose_input(input_dir)
    end

    ##
    # Processa argumentos ARGV e converte em caminhos válidos de arquivos `.txt`.
    # Adiciona extensão `.txt` se ausente e remove arquivos inexistentes.
    #
    # @param input_dir [String] Diretório onde estão os arquivos
    # @return [Array<String>] Caminhos válidos para arquivos de entrada
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

    ##
    # Interface interativa para o usuário selecionar arquivos `.txt` a processar.
    # Exibe uma lista dos arquivos disponíveis e solicita um número ao usuário.
    #
    # @param input_dir [String] Diretório de entrada
    # @return [Array<String>] Lista com o arquivo escolhido ou todos
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

    ##
    # Executa o fluxo completo de geração BDD:
    # - Define o modo (static / IA)
    # - Coleta arquivos de entrada
    # - Valida as histórias
    # - Gera arquivos `.feature` e `steps`
    # - Exporta PDFs e faz backup de versões antigas
    #
    # O modo de execução é lido da variável de ambiente `BDDGENX_MODE`.
    #
    # @return [void]
    def self.execute
      modo = ENV['BDDGENX_MODE'] || 'static'
      input_dir = 'input'
      Dir.mkdir(input_dir) unless Dir.exist?(input_dir)

      arquivos = choose_files(input_dir)
      if arquivos.empty?
        warn I18n.t('messages.no_files')
        exit 1
      end

      # Contadores de geração
      total = features = steps = ignored = 0
      skipped_steps = []
      generated_pdfs = []
      skipped_pdfs = []

      arquivos.each do |arquivo|
        total += 1
        puts "\n🔍 #{I18n.t('messages.processing')}: #{arquivo}"

        historia = Parser.ler_historia(arquivo)
        idioma = IA::GeminiCliente.detecta_idioma_arquivo(arquivo) || historia[:idioma]
        historia[:idioma] = idioma
        unless Validator.validar(historia)
          ignored += 1
          puts "❌ #{I18n.t('messages.invalid_story')}: #{arquivo}"
          next
        end

        # Geração via IA (ChatGPT, Gemini)
        if %w[gemini chatgpt].include?(modo)
          puts I18n.t('messages.start_ia', modo: modo.capitalize)
          idioma = IA::GeminiCliente.detecta_idioma_arquivo(arquivo)

          feature_text = Support::Loader.run(I18n.t('messages.ia_waiting'), :default) do
            case modo
            when 'gemini'
              IA::GeminiCliente.gerar_cenarios(historia, idioma)
            when 'chatgpt'
              IA::ChatGptCliente.gerar_cenarios(historia, idioma)
            end
          end

          if feature_text
            feature_path = Generator.path_para_feature(arquivo)
            feature_content = Bddgenx::GherkinCleaner.limpar(feature_text)
          else
            ignored += 1
            puts I18n.t('messages.feature_fail', arquivo: arquivo)
            next
          end
        else
          # Geração local (modo static)
          feature_path, feature_content = Support::Loader.run(I18n.t('messages.start_static'), :dots) do
            sleep(2)
            Generator.gerar_feature(historia)
          end
        end

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

      # Resumo final
      puts "\n#{I18n.t('messages.processing_done')}"
      puts "- #{I18n.t('messages.total_histories')}:    #{total}"
      puts "- #{I18n.t('messages.features_generated')}: #{features}"
      puts "- #{I18n.t('messages.steps_generated')}:    #{steps}"
    end
  end
end
