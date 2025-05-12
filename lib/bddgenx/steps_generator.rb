require 'fileutils'
require_relative 'utils/verificador'

module Bddgenx
  class StepsGenerator
    PADROES = {
      'pt' => %w[Dado Quando Então E Mas],
      'en' => %w[Given When Then And But]
    }

    def self.gerar_passos(historia, nome_arquivo_feature)
      idioma = historia[:idioma] || 'pt'
      conectores = PADROES[idioma]
      passos_gerados = []

      historia[:grupos].each do |grupo|
        tipo              = grupo[:tipo]
        passos            = grupo[:passos]
        exemplos_brutos   = grupo[:exemplos]
        exemplos = exemplos_brutos&.any? ? dividir_examples(exemplos_brutos) : nil

        next unless passos.is_a?(Array) && passos.any?

        passos.each do |linha|
          conector = conectores.find { |c| linha.strip.start_with?(c) }
          next unless conector

          corpo = linha.strip.sub(/^#{conector}\s*/, '')
          corpo_sanitizado = corpo.gsub(/"(<[^>]+>)"/, '\1')

          grupo_exemplo_compat = nil

          if exemplos
            exemplos.each do |tabela|
              cabecalho = tabela.first.gsub('|', '').split.map(&:strip)
              linhas = tabela[1..].map { |linha| linha.gsub('|', '').split.map(&:strip) }
              if cabecalho.any? { |col| corpo.include?("<#{col}>") }
                grupo_exemplo_compat = {
                  cabecalho: cabecalho,
                  linhas: linhas
                }
                break
              end
            end
          end

          if grupo_exemplo_compat
            parametros = corpo.scan(/<([^>]+)>/).flatten.map(&:strip)
            corpo_param = corpo_sanitizado.gsub(/<([^>]+)>/) do
              nome = $1.strip
              tipo_param = detectar_tipo_param(nome, grupo_exemplo_compat)
              "{#{tipo_param}}"
            end
            args_list = parametros.map { |p| p.gsub(' ', '_') }.join(', ')
            pending_msg = corpo.gsub(/<([^>]+)>/) { |m| "<#{Regexp.last_match(1).strip}>" }
          else
            corpo_param = corpo
            args_list = ''
            pending_msg = corpo
          end

          passos_gerados << {
            conector: conector,
            raw:      pending_msg,
            param:    corpo_param,
            args:     args_list,
            tipo:     tipo
          } unless passos_gerados.any? { |p| p[:param] == corpo_param }
        end
      end

      if passos_gerados.empty?
        puts "⚠️  Nenhum passo detectado em: #{nome_arquivo_feature} (arquivo não gerado)"
        return false
      end

      nome_base = File.basename(nome_arquivo_feature, '.feature')
      caminho   = "steps/#{nome_base}_steps.rb"
      FileUtils.mkdir_p(File.dirname(caminho))

      comentario = "# Step definitions para #{File.basename(nome_arquivo_feature)}"
      comentario += idioma == 'en' ? " (English)" : " (Português)"
      conteudo = "#{comentario}\n\n"

      passos_gerados.each do |passo|
        conteudo += <<~STEP
          #{passo[:conector]}('#{passo[:param]}') do#{passo[:args].empty? ? '' : " |#{passo[:args]}|"}
            pending 'Implementar passo: #{passo[:raw]}'
          end

        STEP
      end

      if Bddgenx::Verificador.gerar_arquivo_se_novo(caminho, conteudo)
        puts "✅ Step definitions gerados: #{caminho}"
      else
        puts "⏭️  Steps mantidos: #{caminho}"
      end
      true
    end

    def self.detectar_tipo_param(nome_coluna, exemplos)
      return 'string' unless exemplos[:cabecalho].include?(nome_coluna)

      idx = exemplos[:cabecalho].index(nome_coluna)
      valores = exemplos[:linhas].map { |l| l[idx].to_s.strip }

      return 'boolean' if valores.all? { |v| %w[true false].include?(v.downcase) }
      return 'int'     if valores.all? { |v| v.match?(/^\d+$/) }
      return 'float'   if valores.all? { |v| v.match?(/^\d+\.\d+$/) }

      'string'
    end

    def self.dividir_examples(tabela_bruta)
      grupos = []
      grupo_atual = []

      tabela_bruta.each do |linha|
        if linha.strip =~ /^\|.*\|$/ && grupo_atual.any? && linha.strip == linha.strip.squeeze(' ')
          grupos << grupo_atual
          grupo_atual = [linha]
        else
          grupo_atual << linha
        end
      end

      grupos << grupo_atual unless grupo_atual.empty?
      grupos
    end
  end
end
