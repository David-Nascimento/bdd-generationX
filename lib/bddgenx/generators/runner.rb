# lib/bddgenx/cli.rb
# encoding: utf-8
#
# Este arquivo define a classe Runner (CLI) da gem BDDGenX.
#
# A Runner é responsável por orquestrar todo o fluxo de geração BDD:
# - Leitura e validação de histórias (arquivos `.txt`)
# - Geração de arquivos `.feature` e steps
# - Integração com IA (ChatGPT, Gemini, Copilot)
# - Exportação para PDF
# - Rastreabilidade via CSV
#
# Esta classe é o ponto de entrada da gem em execução via terminal (CLI).
# O comportamento é configurado com variáveis de ambiente como:
# - BDDGENX_MODE (static, chatgpt, gemini, copilot)
# - BDDGENX_LANG (pt, en)

require_relative '../../bddgenx'

module Bddgenx
  # Classe principal de execução da gem BDDGenX.
  # Controla o fluxo de leitura de histórias, geração de artefatos BDD
  # e exportação de relatórios. Suporta execução via terminal.
  class Runner

    ##
    # Retorna a lista de arquivos `.txt` a processar.
    #
    # - Se ARGV contiver argumentos, usa esses nomes como arquivos `.txt`
    # - Caso contrário, entra em modo interativo para seleção manual
    #
    # @param input_dir [String] Caminho do diretório com arquivos `.txt`
    # @return [Array<String>] Lista de caminhos de arquivos `.txt`
    def self.choose_files(input_dir)
      ARGV.any? ? selecionar_arquivos_txt(input_dir) : choose_input(input_dir)
    end

    ##
    # Processa os argumentos da linha de comando (ARGV) e gera caminhos
    # completos para arquivos `.txt` no diretório informado.
    #
    # - Se a extensão `.txt` estiver ausente, ela é adicionada.
    # - Arquivos inexistentes são ignorados com aviso.
    #
    # @param input_dir [String] Diretório base onde estão os arquivos `.txt`
    # @return [Array<String>] Lista de arquivos válidos encontrados
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
    # Modo interativo para o usuário escolher o arquivo `.txt` a ser processado.
    #
    # Exibe uma lista numerada com os arquivos disponíveis no diretório.
    # O usuário pode selecionar um específico ou pressionar ENTER para todos.
    #
    # @param input_dir [String] Caminho do diretório com arquivos `.txt`
    # @return [Array<String>] Arquivo selecionado ou todos disponíveis
    def self.choose_input(input_dir)
      files = Dir.glob(File.join(input_dir, '*.txt'))
      if files.empty?
        warn "❌ Não há arquivos .txt no diretório #{input_dir}"
        exit 1
      end

      puts "Selecione o arquivo de história para processar:"
      files.each_with_index { |f, i| puts "#{i+1}. #{File.basename(f)}" }
      print "Digite o número correspondente (ou ENTER para todos): "
      choice = STDIN.gets.chomp

      return files if choice.empty?
      idx = choice.to_i - 1
      unless idx.between?(0, files.size - 1)
        warn "❌ Escolha inválida."
        exit 1
      end
      [files[idx]]
    end

    ##
    # Executa o fluxo principal de geração dos artefatos BDD.
    #
    # Etapas executadas:
    # - Detecta o modo de execução via ENV['BDDGENX_MODE'] (static/chatgpt/gemini/copilot)
    # - Carrega e valida histórias de usuário
    # - Gera arquivos `.feature` e seus respectivos steps
    # - Executa geração via IA (quando aplicável)
    # - Exporta arquivos em PDF
    # - Gera rastreabilidade via CSV
    #
    # Exibe no final um resumo das operações executadas.
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

      # Contadores
      total = features = steps = ignored = 0
      skipped_steps = []
      generated_pdfs = []
      skipped_pdfs = []

      arquivos.each do |arquivo|
        total += 1
        puts "\n🔍 #{I18n.t('messages.processing')}: #{arquivo}"

        historia = Parser.ler_historia(arquivo)
        idioma = Utils.obter_idioma_do_arquivo(arquivo) || historia[:idioma]
        historia[:idioma] = idioma

        unless Validator.validar(historia)
          ignored += 1
          puts "❌ #{I18n.t('messages.invalid_story')}: #{arquivo}"
          next
        end

        # IA: geração de cenários com Gemini, ChatGPT ou Copilot
        if %w[gemini chatgpt copilot].include?(modo)
          puts I18n.t('messages.start_ia', modo: modo.capitalize)

          feature_text = Support::Loader.run(I18n.t('messages.ia_waiting'), :default) do
            case modo
            when 'gemini' then IA::GeminiCliente.gerar_cenarios(historia, idioma)
            when 'chatgpt' then IA::ChatGptCliente.gerar_cenarios(historia, idioma)
            when 'copilot' then IA::MicrosoftCopilotCliente.gerar_cenarios(historia, idioma)
            end
          end

          if feature_text
            feature_path = Generator.path_para_feature(arquivo)
            feature_content = Utils.limpar(feature_text)
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

        # Salva versão antiga se existir
        Backup.salvar_versao_antiga(feature_path)

        features += 1 if Generator.salvar_feature(feature_path, feature_content)

        if StepsGenerator.gerar_passos(feature_path)
          steps += 1
        else
          skipped_steps << feature_path
        end

        FileUtils.mkdir_p('reports')
        result = PDFExporter.exportar_todos(only_new: true)
        Tracer.adicionar_entrada(historia, feature_path)

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
