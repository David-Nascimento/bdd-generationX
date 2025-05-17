module Bddgenx
  # Sobe 3 níveis: lib/bddgenx/version.rb → bddgenx → lib → [raiz do projeto]
  VERSION_FILE = File.expand_path("../../VERSION", __FILE__)

  VERSION = if File.exist?(VERSION_FILE)
              File.read(VERSION_FILE).strip
            else
              warn "WARNING: VERSION file not found, defaulting to 0.0.0"
              "0.0.0"
            end
end
