# lib/bddgenx/font_loader.rb
# encoding: utf-8
#
# Este arquivo define a classe FontLoader, responsável por localizar e carregar
# famílias de fontes TrueType para uso com Prawn em geração de PDFs.
# Busca os arquivos de fonte no diretório assets/fonts dentro da gem.
module Bddgenx
  # Gerencia o carregamento de fontes TTF para os documentos PDF.
  class FontLoader
    # Retorna o caminho absoluto para a pasta assets/fonts dentro da gem
    #
    # @return [String] Caminho completo para o diretório de fontes
    def self.fonts_path
      File.expand_path('../../assets/fonts', __dir__)
    end

    # Cria o hash de famílias de fontes para registro no Prawn
    #
    # Verifica se os arquivos de fonte DejaVuSansMono incluem normal, bold,
    # italic e bold_italic e têm tamanho mínimo aceitável.
    # Se estiverem ausentes ou corrompidas, retorna hash vazio para usar fallback.
    #
    # @return [Hash{String => Hash<Symbol, String>}]
    #   - Chave: nome da família ('DejaVuSansMono')
    #   - Valor: mapa de estilos (:normal, :bold, :italic, :bold_italic) para os caminhos dos arquivos
    def self.families
      base = fonts_path
      return {} unless Dir.exist?(base)

      arquivos = {
        normal:      File.join(base, 'DejaVuSansMono.ttf'),
        bold:        File.join(base, 'DejaVuSansMono-Bold.ttf'),
        italic:      File.join(base, 'DejaVuSansMono-Oblique.ttf'),
        bold_italic: File.join(base, 'DejaVuSansMono-BoldOblique.ttf')
      }

      # Verifica existência e tamanho mínimo de cada arquivo
      if arquivos.values.all? { |path| File.file?(path) && File.size(path) > 12 }
        { 'DejaVuSansMono' => arquivos }
      else
        warn I18n.t('errors.font_fallback', font: base)
        {}
      end
    end
  end
end
