
module Bddgenx
  # Módulo para inferir o tipo de parâmetro a partir de exemplos
  class TipoParam
    # Retorna 'string', 'int', 'float' ou 'boolean'
    def self.determine_type(nome, estrutura)
      return 'string' unless estrutura[:cabecalho].include?(nome)
      idx = estrutura[:cabecalho].index(nome)
      vals = estrutura[:linhas].map { |l| l[idx] }
      return 'boolean' if vals.all? { |v| %w[true false].include?(v.downcase) }
      return 'int'     if vals.all? { |v| v.match?(/^\d+$/) }
      return 'float'   if vals.all? { |v| v.match?(/^\d+\.\d+$/) }
      'string'
    end
  end
end