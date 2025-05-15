# lib/bddgenx/font_loader.rb
require 'prawn'
require 'rubygems'  # para Gem.loaded_specs

module Bddgenx
  class FontLoader
    # Retorna o diretório assets/fonts dentro da gem, mesmo em dev local
    def self.fonts_path
      File.expand_path('../../bddgenx/assets/fonts', __dir__)
    end

    # Retorna famílias de fontes TrueType para Prawn; vazio se faltar arquivos
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
        warn "⚠️ Fontes DejaVuSansMono ausentes ou corrompidas em #{base}."
        {}
      end
    end
  end
end
