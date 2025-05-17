# lib/bddgenx/generator.rb
# encoding: utf-8
#
# Este arquivo define a classe Generator, responsável por gerar arquivos
# .feature a partir de um hash de história ou de um arquivo de história em texto.
# Suporta Gherkin em Português e Inglês, inclusão de tags, cenários simples
# e esquemas de cenário com exemplos.
module Bddgenx
  class Generator
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze
    GHERKIN_MAP_PT_EN = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h
    GHERKIN_MAP_EN_PT = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    def self.dividir_examples(raw)
      raw.select { |l| l.strip.start_with?('|') }
    end

    def self.gerar_feature(input, override_path = nil)
      modo = ENV['BDD_MODE']&.to_sym || :static

      # IA: Lê o arquivo txt e passa para IA → aplica limpeza
      if input.is_a?(String) && input.end_with?('.txt') && [:gemini, :chatgpt].include?(modo)
        raw_txt = File.read(input)
        historia = {
          idioma: 'pt',
          quero: File.basename(input, '.txt').tr('_', ' ').capitalize,
          como: '',
          para: '',
          grupos: []
        }

        texto_gerado = if modo == :gemini
                         GeminiCliente.gerar_cenarios(raw_txt)
                       else
                         ChatGPTCliente.gerar_cenarios(raw_txt)
                       end

        historia[:grupos] << {
          tipo: 'gerado',
          tag: 'ia',
          passos: GherkinCleaner.limpar(texto_gerado).lines.map(&:strip).reject(&:empty?)
        }

      else
        # Caminho tradicional (hash de entrada ou parser de arquivo)
        historia = input.is_a?(String) ? Parser.ler_historia(input) : input
      end

      idioma = historia[:idioma] || 'pt'
      cont = 1

      nome_base = historia[:quero]
                    .gsub(/[^a-z0-9]/i, '_')
                    .downcase
                    .split('_')
                    .reject(&:empty?)
                    .first(5)
                    .join('_')

      caminho = override_path || "features/#{nome_base}.feature"

      palavras = {
        feature:  idioma == 'en' ? 'Feature'          : 'Funcionalidade',
        contexto: idioma == 'en' ? 'Background'       : 'Contexto',
        cenario:  idioma == 'en' ? 'Scenario'         : 'Cenário',
        esquema:  idioma == 'en' ? 'Scenario Outline' : 'Esquema do Cenário',
        exemplos: idioma == 'en' ? 'Examples'         : 'Exemplos',
        regra:    idioma == 'en' ? 'Rule'             : 'Regra'
      }

      conteudo = <<~GHK
  # language: #{idioma}
  #{palavras[:feature]}: #{historia[:quero].sub(/^Quero\s*/i,'')}
    # #{historia[:como]}
    # #{historia[:quero]}
    # #{historia[:para]}

      GHK

      # Set para rastrear steps únicos
      passos_unicos = Set.new
      pt_map = GHERKIN_MAP_PT_EN
      en_map = GHERKIN_MAP_EN_PT
      detect = ALL_KEYS
      cont = 1

      historia[:grupos].each do |grupo|
        passos   = grupo[:passos]  || []
        exemplos = grupo[:exemplos] || []
        next if passos.empty?

        tag_line = ["@#{grupo[:tipo].downcase}", ("@#{grupo[:tag]}" if grupo[:tag])].compact.join(' ')

        conteudo << "    #{tag_line}\n"

        if exemplos.any?
          conteudo << "    #{palavras[:esquema]}: Exemplo #{cont}\n"
          cont += 1
        else
          conteudo << "    #{palavras[:cenario]}: #{grupo[:tipo].capitalize}\n"
        end

        passos.each do |p|
          parts = p.strip.split(' ', 2)
          con_in = detect.find { |k| k.casecmp(parts[0]) == 0 } || parts[0]
          text = parts[1] || ''
          out_conn = idioma == 'en' ? pt_map[con_in] || con_in : en_map[con_in] || con_in
          linha_step = "      #{out_conn} #{text}"

          next if passos_unicos.include?(linha_step)

          passos_unicos << linha_step
          conteudo << "#{linha_step}\n"
        end

        if exemplos.any?
          conteudo << "\n      #{palavras[:exemplos]}:\n"
          exemplos.select { |l| l.strip.start_with?('|') }.each do |line|
            cleaned = line.strip.gsub(/^"|"$/, '')
            conteudo << "        #{cleaned}\n"
          end
        end

        conteudo << "\n"
      end

      [caminho, conteudo]
    end

    def self.path_para_feature(arquivo_txt)
      nome = File.basename(arquivo_txt, '.txt')
      File.join('features', "#{nome}.feature")
    end

    def self.salvar_feature(caminho, conteudo)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, conteudo)
      puts "✅ Arquivo .feature gerado: #{caminho}"
    end
  end
end
