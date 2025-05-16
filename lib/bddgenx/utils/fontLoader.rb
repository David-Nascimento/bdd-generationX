# lib/bddgenx/font_loader.rb
require 'prawn'
require 'rubygems'  # para Gem.loaded_specs

module Bddgenx
  class FontLoader
    # Retorna o diretório assets/fonts dentro da gem
    def self.fonts_path
      File.expand_path('../../assets/fonts', __dir__)
    end

    # Carrega famílias de fontes TrueType para Prawn
    def self.families
      base = fonts_path
      return {} unless Dir.exist?(base)

      files = {
        normal:      File.join(base, 'DejaVuSansMono.ttf'),
        bold:        File.join(base, 'DejaVuSansMono-Bold.ttf'),
        italic:      File.join(base, 'DejaVuSansMono-Oblique.ttf'),
        bold_italic: File.join(base, 'DejaVuSansMono-BoldOblique.ttf')
      }

      if files.values.all? { |path| File.file?(path) && File.size(path) > 12 }
        { 'DejaVuSansMono' => files }
      else
        warn "⚠️ Fontes DejaVuSansMono ausentes ou corrompidas em #{base}. Usando fallback Courier."
        {}
      end
    end
  end
end
