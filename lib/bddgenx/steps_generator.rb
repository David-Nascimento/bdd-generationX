require 'fileutils'
require_relative 'utils/tipo_param'
require 'strscan'  # para usar ::StringScanner

# lib/bddgenx/steps_generator.rb

module Bddgenx
  class StepsGenerator
    GHERKIN_KEYS = %w[Dado Quando Então E Mas Given When Then And But].freeze

    # Gera step definitions a partir de um arquivo .feature
    # Placeholders em "<nome>" => string, em <nome> => int, literais "texto" => string
    def self.gerar_passos(feature_path)
      raise ArgumentError, "Caminho esperado como String, recebeu #{feature_path.class}" unless feature_path.is_a?(String)

      lines = File.readlines(feature_path)
      step_lines = lines.map(&:strip)
                        .select { |l| GHERKIN_KEYS.any? { |k| l.start_with?(k + ' ') } }
      return false if step_lines.empty?

      dir = File.join(File.dirname(feature_path), 'steps')
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "#{File.basename(feature_path, '.feature')}_steps.rb")

      content = +"# encoding: utf-8\n# Auto-generated step definitions for #{File.basename(feature_path)}\n\n"

      step_lines.each do |line|
        keyword, rest = line.split(' ', 2)
        raw = rest.dup

        scanner = ::StringScanner.new(rest)
        pattern = ''
        tokens  = []

        until scanner.eos?
          if scanner.check(/"<[^>]+>"/)
            scanner.scan(/"<([^>]+)>"/)
            tokens << scanner[1]
            pattern << '{string}'
          elsif scanner.check(/<[^>]+>/)
            scanner.scan(/<([^>]+)>/)
            tokens << scanner[1]
            pattern << '{int}'
          elsif scanner.check(/"([^"<>]+)"/)
            scanner.scan(/"([^"<>]+)"/)
            tokens << scanner[1]
            pattern << '{string}'
          else
            pattern << scanner.getch
          end
        end

        safe_pattern = pattern.gsub('"', '\\"')
        signature = "#{keyword}(\"#{safe_pattern}\")"

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