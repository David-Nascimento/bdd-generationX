require 'set'
require 'unicode'

module Bddgenx
  module Utils
    class StepCleaner
      def self.remover_steps_duplicados(texto, idioma)
        keywords = idioma == 'en' ? %w[Given When Then And] : %w[Dado Quando Então E]
        seen = Set.new
        resultado = []

        texto.each_line do |linha|
          if keywords.any? { |kw| linha.strip.start_with?(kw) }
            canonical = canonicalize_step(linha, keywords)
            unless seen.include?(canonical)
              seen.add(canonical)
              resultado << linha
            end
          else
            resultado << linha
          end
        end

        resultado.join
      end

      def self.canonicalize_step(linha, keywords)
        # Remove keyword
        texto = linha.dup.strip
        keywords.each do |kw|
          texto.sub!(/^#{kw}\s+/i, '')
        end

        # Generaliza: substitui textos entre aspas, colchetes e números por <param>
        texto.gsub!(/"[^"]*"|<[^>]*>|\b\d+\b/, '<param>')

        # Remove acentos e pontuação, normaliza espaços
        texto = Unicode.normalize_KD(texto).gsub(/\p{Mn}/, '')
        texto.gsub!(/[^a-zA-Z0-9\s<>]/, '')
        texto.downcase.strip.squeeze(" ")
      end
    end
  end
end
