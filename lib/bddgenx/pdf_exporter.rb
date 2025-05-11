require 'prawn'
require 'fileutils'

module Bddgen
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
        pdf.font_size 10
        pdf.text "Arquivo: #{File.basename(origem)}", style: :bold, size: 14
        pdf.move_down 10
        pdf.text conteudo, size: 10
      end
    end
  end
end
