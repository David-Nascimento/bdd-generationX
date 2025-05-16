# lib/bddgenx/pdf_exporter.rb
require 'prawn'
require 'prawn/table'
require 'fileutils'
require_relative 'fontLoader'

# Suprime aviso de internacionalização para fontes AFM built-in
Prawn::Fonts::AFM.hide_m17n_warning = true

module Bddgenx
  class PDFExporter
    # Gera PDFs a partir de arquivos .feature no estilo pretty Cucumber em P/B
    # Params:
    # +caminho_feature+:: (String) caminho para um arquivo .feature específico. Se nil, gera para todos em features/*.feature
    # +only_new+:: (Boolean) se true, não sobrescreve PDFs já existentes
    def self.exportar_todos(caminho_feature: nil, only_new: false)
      FileUtils.mkdir_p('reports/pdf')
      features_list = if caminho_feature && !caminho_feature.empty?
                        [caminho_feature]
                      else
                        Dir.glob('features/*.feature')
                      end

      generated, skipped = [], []
      features_list.each do |feature|
        unless File.file?(feature)
          warn "⚠️ Feature não encontrada: #{feature}"
          next
        end
        nome    = File.basename(feature, '.feature')
        destino = "reports/pdf/#{camel_case(nome)}.pdf"

        if only_new && File.exist?(destino)
          skipped << destino
          next
        end

        exportar_arquivo(feature, destino)
        generated << destino
      end

      { generated: generated, skipped: skipped }
    end

    # Converte string para camelCase, removendo caracteres especiais
    def self.camel_case(str)
      clean = str.gsub(/[^0-9A-Za-z ]/, '')
      parts = clean.split(/ |_/)
      ([parts.first&.downcase] + (parts[1..] || []).map(&:capitalize)).join
    end

    # Gera o PDF formatado a partir de um único arquivo .feature, sem executar testes
    def self.exportar_arquivo(origem, destino)
      FileUtils.mkdir_p(File.dirname(destino))
      conteudo = File.read(origem, encoding: 'utf-8')

      Prawn::Document.generate(destino, page_size: 'A4', margin: 50) do |pdf|
        pdf.font 'Courier'
        pdf.font_size 9

        table_buffer = []
        conteudo.each_line do |linha|
          text = linha.chomp

          # Agrupa linhas de tabela e renderiza quando termina
          if text =~ /^\s*\|.*\|/i
            table_buffer << text.gsub(/^\s*\||\|\s*$/, '').split('|').map(&:strip)
            next
          elsif table_buffer.any?
            pdf.table(table_buffer, header: true, width: pdf.bounds.width) do
              self.header = true
              self.row_colors = ['EEEEEE', 'FFFFFF']
              self.cell_style = { size: 8, font: 'Courier' }
            end
            pdf.move_down 4
            table_buffer.clear
          end

          case text
          when /^\s*(Feature|Funcionalidade):/i
            pdf.move_down 6
            pdf.text text, size: 14, style: :bold
            pdf.move_down 4
          when /^\s*(Background):/i
            pdf.text text, size: 11, style: :italic
            pdf.move_down 4
          when /^\s*(Scenario(?: Outline)?|Esquema do Cenário):/i
            pdf.move_down 6
            pdf.text text, size: 12, style: :bold
            pdf.move_down 4
          when /^\s*(Examples|Exemplos):/i
            pdf.text text, size: 11, style: :bold
            pdf.move_down 4
          when /^\s*@/i
            pdf.text text, size: 8, style: :italic
            pdf.move_down 4
          when /^(?:\s*)(Given|When|Then|And|But|Dado|Quando|Então|E|Mas)\b/i
            keyword, rest = text.strip.split(' ', 2)
            pdf.indent(20) do
              pdf.formatted_text [
                                   { text: keyword, styles: [:bold] },
                                   { text: rest ? " #{rest}" : '' }
                                 ], size: 9
            end
            pdf.move_down 2
          when /^\s*$/
            pdf.move_down 4
          else
            pdf.text text
          end
        end

        # Renderiza qualquer tabela remanescente
        if table_buffer.any?
          pdf.table(table_buffer, header: true, width: pdf.bounds.width) do
            self.header = true
            self.row_colors = ['EEEEEE', 'FFFFFF']
            self.cell_style = { size: 8, font: 'Courier' }
          end
          pdf.move_down 4
        end

        pdf.number_pages 'Página <page> de <total>', align: :right, size: 8
      end
    rescue => e
      warn "❌ Erro ao gerar PDF de #{origem}: #{e.message}"
    end
  end
end