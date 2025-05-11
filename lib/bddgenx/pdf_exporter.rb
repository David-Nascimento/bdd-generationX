require 'prawn'
require 'fileutils'

module Bddgenx
  class PDFExporter
    def self.exportar_todos
      FileUtils.mkdir_p('pdf')

      Dir.glob('features/*.feature').each do |feature_file|
        nome = File.basename(feature_file, '.feature')
        destino = "pdf/#{nome}.pdf"
        exportar_arquivo(feature_file, destino)
        puts "📄 PDF gerado: #{destino}"
      end
    end

    def self.exportar_arquivo(origem, destino)
      conteudo = File.read(origem, encoding: 'utf-8')

      Prawn::Document.generate(destino) do |pdf|
        # Fontes externas com suporte UTF-8
        pdf.font_families.update(
          "DejaVu" => {
            normal: "fonts/DejaVuSansMono.ttf",
            bold: "fonts/DejaVuSansMono-Bold.ttf",
            italic: "fonts/DejaVuSansMono-Oblique.ttf",
            bold_italic: "fonts/DejaVuSansMono-BoldOblique.ttf"
          }
        )
        pdf.font "DejaVu"
        pdf.font_size 10

        pdf.text "📄 #{File.basename(origem)}", style: :normal, size: 14
        pdf.move_down 10

        conteudo.each_line do |linha|
          linha = linha.strip

          case linha
          when /^#/
            pdf.fill_color "888888"
            pdf.text linha, style: :italic, size: 8
            pdf.fill_color "000000"

          when /^Funcionalidade:|^Feature:/
            pdf.move_down 6
            pdf.text linha, style: :bold, size: 12
            pdf.move_down 4

          when /^Cenário:|^Scenario:|^Esquema do Cenário:|^Scenario Outline:/
            pdf.move_down 4
            pdf.text linha, style: :bold

          when /^@/
            pdf.text linha, style: :italic, color: "555555"

          when /^(Dado|Quando|Então|E|Mas|Given|When|Then|And|But)\b/
            pdf.indent(20) do
              pdf.text linha
            end

          when /^Exemplos:|^Examples:/
            pdf.move_down 4
            pdf.text linha, style: :bold

          when /^\|.*\|$/
            pdf.indent(20) do
              pdf.font_size 9
              pdf.text linha, font: "DejaVu"
              pdf.font_size 10
            end

          when /^\s*$/
            pdf.move_down 4

          else
            pdf.text linha
          end
        end

        pdf.move_down 20
        pdf.number_pages "Página <page> de <total>", align: :right, size: 8
      end
      rescue => e
        puts "❌ Erro ao gerar PDF de #{origem}: #{e.message}"
    end
  end
end

# Execute automaticamente se chamado como script direto
if __FILE__ == $PROGRAM_NAME
  Bddgen::PDFExporter.exportar_todos
end
