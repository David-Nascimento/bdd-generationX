# lib/bddgenx/pdf_exporter.rb
# encoding: utf-8
#
# Este arquivo define a classe PDFExporter, responsável por gerar documentos
# PDF a partir de arquivos .feature, formatados no estilo pretty Cucumber em
# preto e branco.
# Utiliza a gem Prawn para renderização de texto e tabelas.

# Suprime aviso de internacionalização para fontes AFM internas
Prawn::Fonts::AFM.hide_m17n_warning = true

module Bddgenx
  # Gera documentos PDF baseados em arquivos .feature.
  class PDFExporter
    # Gera PDFs de features, criando um para cada arquivo .feature ou apenas para
    # o especificado em caminho_feature.
    #
    # @param caminho_feature [String, nil]
    #   Caminho para um arquivo .feature específico. Se nil ou vazio, gera para todos
    #   os arquivos em features/*.feature.
    # @param only_new [Boolean]
    #   Se true, não sobrescreve arquivos PDF já existentes.
    # @return [Hash<Symbol, Array<String>>]
    #   Retorna um hash com duas chaves:
    #   - :generated => array de caminhos dos PDFs gerados
    #   - :skipped   => array de caminhos dos PDFs que foram pulados
    def self.exportar_todos(caminho_feature: nil, only_new: false)
      FileUtils.mkdir_p('reports/pdf')
      features_list = if caminho_feature && !caminho_feature.empty?
                        [caminho_feature]
                      else
                        Dir.glob('features/*.feature')
                      end

      generated = []
      skipped   = []

      features_list.each do |feature|
        unless File.file?(feature)
          warn I18n.t('errors.feature_not_found', feature: feature)
          next
        end

        nome     = File.basename(feature, '.feature')
        destino  = "reports/pdf/#{camel_case(nome)}.pdf"

        if only_new && File.exist?(destino)
          skipped << destino
          next
        end

        exportar_arquivo(feature, destino)
        generated << destino
      end

      { generated: generated, skipped: skipped }
    end

    # Converte uma string para formato camelCase, removendo caracteres especiais.
    #
    # @param str [String] A string de entrada a ser transformada.
    # @return [String] String no formato camelCase.
    def self.camel_case(str)
      clean = str.gsub(/[^0-9A-Za-z ]/, '')
      parts = clean.split(/ |_/)
      ([parts.first&.downcase] + (parts[1..] || []).map(&:capitalize)).join
    end

    # Gera um documento PDF a partir de um arquivo .feature, aplicando estilos
    # de cabeçalhos, cenários, passos e tabelas conforme padrões Cucumber.
    #
    # @param origem [String] Caminho para o arquivo .feature de origem.
    # @param destino [String] Caminho onde o PDF será salvo.
    # @return [void]
    def self.exportar_arquivo(origem, destino)
      FileUtils.mkdir_p(File.dirname(destino))
      conteudo = File.read(origem, encoding: 'utf-8')

      Prawn::Document.generate(destino, page_size: 'A4', margin: 50) do |pdf|
        pdf.font 'Courier'
        pdf.font_size 9

        table_buffer = []

        conteudo.each_line do |linha|
          text = linha.chomp

          # Agrega linhas de tabela até o bloco terminar
          if text =~ /^\s*\|.*\|/i
            # Remove bordas laterais e separa colunas
            row = text.gsub(/^\s*\||\|\s*$/, '').split('|').map(&:strip)
            table_buffer << row
            next
          elsif table_buffer.any?
            # Renderiza tabela acumulada
            pdf.table(table_buffer, header: true, width: pdf.bounds.width) do
              self.header      = true
              self.row_colors  = ['EEEEEE', 'FFFFFF']
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
            # Passo Gherkin: destaca palavra-chave e texto
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

        # Renderiza tabela remanescente, se houver
        if table_buffer.any?
          pdf.table(table_buffer, header: true, width: pdf.bounds.width) do
            self.header      = true
            self.row_colors  = ['EEEEEE', 'FFFFFF']
            self.cell_style = { size: 8, font: 'Courier' }
          end
          pdf.move_down 4
        end

        # Numeração de páginas
        pdf.number_pages 'Página <page> de <total>', align: :right, size: 8
      end
    rescue => e
      warn I18n.t('errors.pdf_generation_failed', file: origem, error: e.message)
    end
  end
end
