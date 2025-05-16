require 'fileutils'
require_relative 'utils/tipo_param'

module Bddgenx
  class Generator
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze
    GHERKIN_MAP_PT_EN = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h
    GHERKIN_MAP_EN_PT = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    # Divide raw example blocks into a single table
    def self.dividir_examples(raw)
      raw.select { |l| l.strip.start_with?('|') }
    end

    # Gera .feature a partir de hash ou arquivo de história
    # Respeita idioma em historia[:idioma]
    def self.gerar_feature(input, override_path = nil)
      historia = input.is_a?(String) ? Parser.ler_historia(input) : input
      idioma = historia[:idioma] || 'pt'
      nome_base = historia[:quero].gsub(/[^a-z0-9]/i, '_')
                                  .downcase.split('_',3)[0,3].join('_')
      caminho = override_path.is_a?(String) ? override_path : "features/#{nome_base}.feature"

      palavras = {
        feature:   idioma=='en' ? 'Feature'           : 'Funcionalidade',
        contexto:  idioma=='en' ? 'Background'        : 'Contexto',
        cenario:   idioma=='en' ? 'Scenario'          : 'Cenário',
        esquema:   idioma=='en' ? 'Scenario Outline'  : 'Esquema do Cenário',
        exemplos:  idioma=='en' ? 'Examples'          : 'Exemplos',
        regra:     idioma=='en' ? 'Rule'              : 'Regra'
      }

      conteudo = <<~GHK
        # language: #{idioma}
        #{palavras[:feature]}: #{historia[:quero].sub(/^Quero\s*/i,'')}
          # #{historia[:como]}
          # #{historia[:quero]}
          # #{historia[:para]}

      GHK

      pt_map = GHERKIN_MAP_PT_EN
      en_map = GHERKIN_MAP_EN_PT
      detect = ALL_KEYS

      historia[:grupos].each_with_index do |grupo, idx|
        passos = grupo[:passos] || []
        exemplos = grupo[:exemplos] || []
        next if passos.empty?

        tag_line = ["@#{grupo[:tipo].downcase}", ("@#{grupo[:tag]}" if grupo[:tag])].compact.join(' ')

        if exemplos.any?
          # Scenario Outline
          conteudo << "    #{tag_line}\n"
          conteudo << "    #{palavras[:esquema]}: #{historia[:quero]}\n"

          # Renderiza cada passo, mapeando connector mesmo se não for Gherkin padrão
          passos.each do |p|
            line = p.strip
            parts = line.split(' ', 2)
            # match connector case-insensitive
            con_in = detect.find { |k| k.casecmp(parts[0]) == 0 } || parts[0]
            text = parts[1] || ''
            out_conn = idioma=='en' ? pt_map[con_in] || con_in : en_map[con_in] || con_in
            conteudo << "      #{out_conn} #{text}
"
          end

          # Monta tabela de exemplos completa
          # Renderiza o bloco de Examples exatamente como veio no TXT
          conteudo << "\n      #{palavras[:exemplos]}:\n"
          exemplos.select { |l| l.strip.start_with?('|') }.each do |line|
            # Remove aspas apenas das células, mantendo todas as colunas e valores originais
            cleaned = line.strip.gsub(/^"|"$/, '')
            conteudo << "        #{cleaned}\n"
          end
          conteudo << "\n"
        else
          # Scenario simples
          conteudo << "    #{tag_line}\n"
          conteudo << "    #{palavras[:cenario]}: #{grupo[:tipo].capitalize}\n"
          passos.each do |p|
            line = p.strip
            parts = line.split(' ', 2)
            # match connector case-insensitive
            con_in = detect.find { |k| k.casecmp(parts[0]) == 0 } || parts[0]
            text = parts[1] || ''
            out_conn = idioma=='en' ? pt_map[con_in] || con_in : en_map[con_in] || con_in
            conteudo << "      #{out_conn} #{text}
"
          end
          conteudo << "\n"
        end
      end

      [caminho, conteudo]
    end

    def self.salvar_feature(caminho, conteudo)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, conteudo)
      puts "✅ Arquivo .feature gerado: #{caminho}"
    end
  end
end