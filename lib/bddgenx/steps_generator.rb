require 'fileutils'
require_relative 'utils/tipo_param'
require 'strscan'  # para usar ::StringScanner

# lib/bddgenx/steps_generator.rb

module Bddgenx
  class StepsGenerator
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze
    ALL_KEYS        = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    # Converte texto para camelCase (para nomes de argumentos)
    def self.camelize(str)
      parts = str.strip.split(/[^a-zA-Z0-9]+/)
      parts.map.with_index { |w, i| i.zero? ? w.downcase : w.capitalize }.join
    end

    # Gera step definitions a partir de um arquivo .feature
    # - "<nome>" => {string}
    # - <nome>   => {int}
    # - "texto" => {string}
    # - numeros inteiros ou floats soltos => {int}
    # Respeita idioma de entrada (pt/en) para keywords geradas
    def self.gerar_passos(feature_path)
      raise ArgumentError, "Caminho esperado como String, recebeu #{feature_path.class}" unless feature_path.is_a?(String)

      lines = File.readlines(feature_path)
      # Detecta idioma no cabeçalho: "# language: pt" ou "# language: en"
      lang = if (m = lines.find { |l| l =~ /^#\s*language:\s*(\w+)/i })
               m[/^#\s*language:\s*(\w+)/i, 1].downcase
             else
               'pt'
             end

      pt_to_en = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h
      en_to_pt = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

      # Seleciona apenas linhas de passo
      step_lines = lines.map(&:strip).select do |l|
        ALL_KEYS.any? { |k| l.start_with?(k + ' ') }
      end
      return false if step_lines.empty?

      dir = File.join(File.dirname(feature_path), 'steps')
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "#{File.basename(feature_path, '.feature')}_steps.rb")

      content = +"# encoding: utf-8\n# Auto-generated step definitions for #{File.basename(feature_path)}\n\n"

      step_lines.each do |line|
        # Extrai keyword original e resto do passo
        orig_kw, rest = line.split(' ', 2)
        # Converte keyword conforme idioma de entrada
        kw = case lang
             when 'en' then pt_to_en[orig_kw] || orig_kw
             else         en_to_pt[orig_kw] || orig_kw
             end
        raw = rest.dup

        scanner = ::StringScanner.new(rest)
        pattern = ''
        tokens  = []

        until scanner.eos?
          if scanner.check(/"<([^>]+)>"/)
            scanner.scan(/"<([^>]+)>"/)
            tokens << scanner[1]
            pattern << '{string}'
          elsif scanner.check(/<([^>]+)>/)
            scanner.scan(/<([^>]+)>/)
            tokens << scanner[1]
            pattern << '{int}'
          elsif scanner.check(/"([^"<>]+)"/)
            scanner.scan(/"([^"<>]+)"/)
            tokens << scanner[1]
            pattern << '{string}'
          elsif scanner.check(/\d+(?:\.\d+)?/)
            num = scanner.scan(/\d+(?:\.\d+)?/)
            tokens << num
            pattern << '{int}'
          else
            pattern << scanner.getch
          end
        end

        # Escapa aspas no padrão final
        safe_pattern = pattern.gsub('"', '\\"')
        signature = "#{kw}(\"#{safe_pattern}\")"

        if tokens.any?
          args = tokens.each_index.map { |i| "args#{i+1}" }.join(', ')
          signature += " do |#{args}|"
        else
          signature += ' do'
        end

        content << signature << "\n"
        content << "  pending 'Implementar passo: #{raw}'\n"
        content << "end\n\n"
      end

      File.write(file, content)
      puts "✅ Steps gerados: #{file}"
      true
    end
  end
end