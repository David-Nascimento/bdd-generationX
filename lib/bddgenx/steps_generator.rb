require 'fileutils'
require_relative 'utils/tipo_param'

module Bddgenx
  class StepsGenerator
    GHERKIN_KEYS = %w[Dado Quando Então E Mas Given When Then And But].freeze

    # Converte texto para camelCase
    def self.camelize(str)
      parts = str.gsub(/<|>/, '') # remove < >
                 .split(/[^a-zA-Z0-9]+/)
      parts.map.with_index { |w, i| i.zero? ? w.downcase : w.capitalize }.join
    end

    # Gera step definitions para todos os passos e placeholders dinâmicos
    def self.gerar_passos(feature_path)
      raise ArgumentError, "Caminho esperado como String, recebeu #{feature_path.class}" unless feature_path.is_a?(String)

      lines = File.readlines(feature_path)
      # Filtra apenas linhas que iniciam com palavras-chave Gherkin
      step_lines = lines.map(&:strip).select { |l| GHERKIN_KEYS.any? { |k| l.start_with?(k + ' ') } }
      return false if step_lines.empty?

      dir = File.join(File.dirname(feature_path), 'steps')
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "#{File.basename(feature_path, '.feature')}_steps.rb")

      content = <<~RUBY
        # encoding: utf-8
        # Auto-generated step definitions for #{File.basename(feature_path)}

      RUBY

      step_lines.each do |line|
        # Extrai keyword e resto do texto
        keyword, rest = line.split(' ', 2)

        # Detecta placeholders <...> e literais "..."
        raw = rest.dup
        placeholders = []

        # Primeiro, trata literais entre aspas
        rest2 = rest.gsub(/"([^"]+)"/) do
          placeholders << $1.strip
          '{string}'
        end

        # Em seguida, trata placeholders <nome>
        rest3 = rest2.gsub(/<([^>]+)>/) do
          placeholders << $1.strip
          '{string}'
        end

        # Monta assinatura
        signature = "#{keyword}(\"#{rest3}\")"
        if placeholders.any?
          arg_names = placeholders.map { |p| camelize(p) }
          signature += " do |#{arg_names.join(', ')}|"
        else
          signature += ' do'
        end

        # Gera bloco
        content << signature + "\n"
        content << "  pending \'Implementar passo: #{raw}\'\n"
        content << "end\n\n"
      end

      File.write(file, content)
      puts "✅ Steps gerados: #{file}"
      true
    end
  end
end