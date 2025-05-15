# lib/bddgenx/pdf_exporter.rb
require 'prawn'
require 'fileutils'
require_relative 'fontLoader'

module Bddgenx
  class PDFExporter
    KEYWORD_COLORS = {
      'Given' => '0000FF',
      'When'  => '008000',
      'Then'  => '800080',
      'And'   => '000000',
      'But'   => 'FF0000'
    }

    def self.exportar_todos(only_new: false)
      FileUtils.mkdir_p('reports/pdf')
      generated, skipped = [], []
      Dir.glob('features/*.feature').each do |feature|
        nome    = File.basename(feature, '.feature')
        destino = "reports/pdf/#{camel_case(nome)}.pdf"
        if File.exist?(destino)
          skipped << destino
        else
          exportar_arquivo(feature, destino)
          generated << destino
        end
      end
      { generated: generated, skipped: skipped }
    end

    def self.camel_case(str)
      clean = str.gsub(/[^0-9A-Za-z ]/, '')
      parts = clean.split(/ |_/)
      ([parts.first&.downcase] + (parts[1..] || []).map(&:capitalize)).join
    end

    def self.exportar_arquivo(origem, destino)
      FileUtils.mkdir_p(File.dirname(destino))
      conteudo = File.read(origem, encoding: 'utf-8')

      families = FontLoader.families
      usar_ttf = !families.empty?

      Prawn::Document.generate(destino, page_size: 'A4', margin: 50) do |pdf|
        if usar_ttf
          pdf.font_families.update(families)
          pdf.font 'DejaVuSansMono'
        else
          pdf.font 'Courier'
        end
        pdf.font_size 10

        # Cabeçalho da Feature
        feature_title = conteudo.lines.find { |l| l =~ /^Feature:/i }&.strip || File.basename(origem)
        pdf.text feature_title, size: 18, style: :bold
        pdf.move_down 8

        # Descrição pós-Feature
        descr = []
        conteudo.each_line.drop_while { |l| l !~ /^Feature:/i }.drop(1).each do |l|
          break unless l.strip.start_with?('#')
          descr << l.strip.sub(/^#\s*/, '')
        end
        unless descr.empty?
          pdf.text descr.join("\n"), size: 11, align: :left
          pdf.move_down 12
        end

        examples_rows = []
        conteudo.each_line do |linha|
          text = linha.chomp
          next if text =~ /^#\s*language:/i

          # Coleciona linhas de tabela
          if text =~ /^\|.*\|$/
            examples_rows << text.gsub(/^\||\|$/, '').split('|').map(&:strip)
            next
          else
            if examples_rows.any?
              pdf.table(examples_rows, header: true, width: pdf.bounds.width) do
                self.header = true
                self.row_colors = ['EFEFEF', 'FFFFFF']
                self.cell_style = { size: 9, font: pdf.font }
              end
              pdf.move_down 6
              examples_rows.clear
            end
          end

          case text
          when /^Scenario Outline:/i, /^Scenario:/i
            pdf.stroke_color 'CCCCCC'
            pdf.stroke_horizontal_rule
            pdf.stroke_color '000000'
            pdf.move_down 6
            pdf.text text, size: 14, style: :bold
            pdf.move_down 6
          when /^Examples:/i
            pdf.text text, size: 12, style: :bold
            pdf.move_down 4
          when /^(Given|When|Then|And|But)\b/i
            keyword, rest = text.split(' ', 2)
            color = KEYWORD_COLORS[keyword] || '000000'
            pdf.indent(20) do
              pdf.formatted_text [
                                   { text: keyword, styles: [:bold], color: color },
                                   { text: " " + (rest || ''), color: '000000' }
                                 ], size: 10
            end
            pdf.move_down 2
          when /^@/  # tags
            pdf.formatted_text [
                                 { text: text, styles: [:italic], size: 9, color: '555555' }
                               ]
            pdf.move_down 4
          when /^#/  # comentários
            pdf.text text.sub(/^#\s*/, ''), size: 9, style: :italic, color: '777777'
            pdf.move_down 4
          when ''
            pdf.move_down 4
          else
            pdf.text text
          end
        end

        # Exibe última tabela se houver
        if examples_rows.any?
          pdf.table(examples_rows, header: true, width: pdf.bounds.width) do
            self.header = true
            self.row_colors = ['EFEFEF', 'FFFFFF']
            self.cell_style = { size: 9, font: pdf.font }
          end
        end

        pdf.move_down 20
        pdf.number_pages('Página <page> de <total>', align: :right, size: 8)
      end
    rescue => e
      warn "❌ Erro ao gerar PDF de #{origem}: #{e.message}"
    end
  end
end

