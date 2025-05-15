require 'fileutils'
require_relative 'utils/tipo_param'

module Bddgenx
  class Generator
    # Gera .feature diretamente baseado no arquivo .txt, sem alterar placeholders
    # Exibe todos os passos e exemplos conforme fornecidos
    def self.gerar_feature(input, override_path = nil)
      historia = input.is_a?(String) ? Parser.ler_historia(input) : input
      nome_base = historia[:quero].gsub(/[^a-z0-9]/i, '_').downcase.split('_',3)[0,3].join('_')
      caminho   = override_path.is_a?(String) ? override_path : "features/#{nome_base}.feature"

      idioma   = historia[:idioma] || 'pt'
      palavras = {
        feature:   idioma == 'en' ? 'Feature' : 'Funcionalidade',
        contexto:  idioma == 'en' ? 'Background' : 'Contexto',
        cenario:   idioma == 'en' ? 'Scenario' : 'Cenário',
        esquema:   idioma == 'en' ? 'Scenario Outline' : 'Esquema do Cenário',
        exemplos:  idioma == 'en' ? 'Examples' : 'Exemplos',
        regra:     idioma == 'en' ? 'Rule' : 'Regra'
      }

      conteudo = <<~GHK
        # language: #{idioma}
        #{palavras[:feature]}: #{historia[:quero].sub(/^Quero\s*/i,'')}
      GHK

      # Gera blocos conforme grupos
      historia[:grupos].each do |grupo|
        tipo = grupo[:tipo]
        tag  = grupo[:tag]
        passos = grupo[:passos] || []
        exemplos = grupo[:exemplos] || []
        next if passos.empty?

        tag_line = ["@#{tipo.downcase}", ("@#{tag}" if tag)].compact.join(' ')

        if exemplos.any?
          # Cenario Outline
          conteudo << "\n    #{tag_line}\n"
          conteudo << "    #{palavras[:esquema]}: #{tipo.capitalize}\n"
          passos.each { |p| conteudo << "      #{p.strip}\n" }
          conteudo << "\n      #{palavras[:exemplos]}:\n"
          exemplos.each do |l|
            conteudo << "        #{l.strip}\n"
          end
          conteudo << "\n"
        else
          # Cenario simples
          conteudo << "\n    #{tag_line}\n"
          conteudo << "    #{palavras[:cenario]}: #{tipo.capitalize}\n"
          passos.each { |p| conteudo << "      #{p.strip}\n" }
          conteudo << "\n"
        end
      end

      [caminho, conteudo]
    end

    # Salva arquivo .feature
    def self.salvar_feature(caminho, conteudo)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, conteudo)
    end
  end
end