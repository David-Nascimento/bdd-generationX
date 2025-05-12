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
        if File.exist?(destino)
          puts "⚠️  PDF já existente: #{destino} — pulando geração."
          return
        else
          puts "📄 PDF gerado: #{destino}"
        end
      end
    end

    def self.sanitizar_utf8_para_ascii(linha)
      linha.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
    rescue Encoding::UndefinedConversionError
      linha.tr('áéíóúãõçâêîôûÁÉÍÓÚÃÕÇÂÊÎÔÛ', 'aeiouaocaeiouAEIOUAOCAEOU')
    end

    def self.exportar_arquivo(origem, destino)
      conteudo = File.read(origem, encoding: 'utf-8')

      Prawn::Document.generate(destino) do |pdf|
        fonte_existe = File.exist?("assets/fonts/DejaVuSansMono.ttf")
        font_dir = File.expand_path("assets/fonts", __dir__)

        if File.exist?(File.join(font_dir, "DejaVuSansMono.ttf"))
          pdf.font_families.update(
            "DejaVu" => {
              normal: File.join(font_dir, "DejaVuSansMono.ttf"),
              bold: File.join(font_dir, "DejaVuSansMono-Bold.ttf"),
              italic: File.join(font_dir, "DejaVuSansMono-Oblique.ttf"),
              bold_italic: File.join(font_dir, "DejaVuSansMono-BoldOblique.ttf")
            }
          )
          pdf.font "DejaVu"
        else
          puts "⚠️ Fonte não encontrada: #{font_dir}"
          pdf.font "Courier"
        end

        pdf.font_size 10
        pdf.text "📄 #{File.basename(origem)}", style: :bold, size: 14
        pdf.move_down 10

        conteudo.each_line do |linha|
          linha = fonte_existe ? linha.strip : sanitizar_utf8_para_ascii(linha.strip)

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
            pdf.indent(20) { pdf.text linha }
          when /^Exemplos:|^Examples:/
            pdf.move_down 4
            pdf.text linha, style: :bold
          when /^\|.*\|$/
            pdf.indent(20) { pdf.text linha }
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
