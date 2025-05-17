require 'set'
require 'unicode'

module Bddgenx
  class GherkinCleaner
    def self.limpar(texto)
      texto = remover_blocos_markdown(texto)
      texto = corrigir_language(texto)
      texto = corrigir_indentacao(texto)
      texto.strip
    end

    def self.remover_blocos_markdown(texto)
      texto.gsub(/```[a-z]*\n?/i, '').gsub(/```/, '')
    end

    def self.corrigir_language(texto)
      linhas = texto.lines
      primeira_language = linhas.find { |linha| linha.strip.start_with?('# language:') }

      # Remove duplicações de # language
      linhas.reject! { |linha| linha.strip.start_with?('# language:') }

      if primeira_language
        linhas.unshift(primeira_language.strip + "\n")
      else
        idioma = detectar_idioma(linhas.join)
        linhas.unshift("# language: #{idioma}\n")
      end

      linhas.join
    end

    def self.detectar_idioma(texto)
      return 'pt' if texto =~ /Dado|Quando|Então|E /i
      return 'en' if texto =~ /Given|When|Then|And /i
      'pt' # padrão
    end

    def self.corrigir_indentacao(texto)
      linhas = texto.lines.map do |linha|
        if linha.strip.start_with?('Feature', 'Funcionalidade')
          linha.strip + "\n"
        elsif linha.strip.start_with?('Scenario', 'Cenário', 'Scenario Outline', 'Esquema do Cenário')
          "  #{linha.strip}\n"
        elsif linha.strip.start_with?('Given', 'When', 'Then', 'And', 'Dado', 'Quando', 'Então', 'E')
          "    #{linha.strip}\n"
        elsif linha.strip.start_with?('|')
          "      #{linha.strip}\n"
        else
          "  #{linha.strip}\n"
        end
      end
      linhas.join
    end
  end
end
