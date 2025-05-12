require 'prawn'
require 'fileutils'

module Bddgenx
  class PDFExporter
    def self.exportar_todos
      FileUtils.mkdir_p('pdf')

      Dir.glob('features/*.feature').each do |feature_file|
        base = File.basename(feature_file, '.feature')
        nome_pdf = camel_case(base)
        destino = "pdf/#{nome_pdf}.pdf"
        exportar_arquivo(feature_file, destino)
        if File.exist?(destino)
          return puts "⚠️  PDF já existente: #{destino} — pulando geração."
        else
          puts "📄 PDF gerado: #{destino}"
        end
      end
    end

    # Converte string para camelCase, removendo caracteres especiais
    def self.camel_case(str)
      # Remove tudo que não for letra ou número ou espaço
      str = str.gsub(/[^0-9A-Za-z ]/, '')
      parts = str.split(/ |_/)
      # Primeira palavra minúscula, demais capitalizadas
      ([parts.first&.downcase] + parts[1..].map(&:capitalize)).join
    end

    def self.sanitizar_utf8_para_ascii(texto)
      if texto.respond_to?(:unicode_normalize)
        # Decompõe em base + acentos, remove acentos, e garante ASCII
        texto
          .unicode_normalize(:nfkd)           # separa letra + marca
          .chars
          .reject { |c| c.match?(/\p{Mn}/) }  # descarta marcas de acento
          .join
          .encode('ASCII', undef: :replace, replace: '?')
      else
        # Fallback simples se por algum motivo unicode_normalize não existir
        texto
          .gsub(/[áàâãä]/i, 'a')
          .gsub(/[éèêë]/i, 'e')
          .gsub(/[íìîï]/i, 'i')
          .gsub(/[óòôõö]/i, 'o')
          .gsub(/[úùûü]/i, 'u')
          .gsub(/[ç]/i,  'c')
          .encode('ASCII', undef: :replace, replace: '?')
      end
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
          linha = fonte_existe ? linha.strip : sanitizar_utf8_para_ascii(linha.chomp)

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
