module Bddgenx
  module Utils
    class StepCleaner
      # Remove passos duplicados em um texto de cenários BDD,
      # levando em conta o idioma para identificar as keywords (Given, When, Then, And / Dado, Quando, Então, E)
      #
      # Parâmetros:
      # - texto: string contendo o texto do cenário BDD
      # - idioma: 'en' para inglês ou qualquer outro para português
      #
      # Retorna o texto com passos duplicados removidos, preservando a ordem original
      def self.remover_steps_duplicados(texto, idioma)
        # Define as keywords principais para o idioma
        keywords = idioma == 'en' ? %w[Given When Then And] : %w[Dado Quando Então E]

        # Conjunto para rastrear passos já vistos (versão canônica)
        seen = Set.new
        resultado = []

        # Percorre linha a linha
        texto.each_line do |linha|
          # Verifica se a linha começa com uma das keywords
          if keywords.any? { |kw| linha.strip.start_with?(kw) }
            # Canonicaliza o passo para comparação sem variações irrelevantes
            canonical = canonicalize_step(linha, keywords)

            # Só adiciona se ainda não viu o passo canônico
            unless seen.include?(canonical)
              seen.add(canonical)
              resultado << linha
            end
          else
            # Linhas que não são passos são adicionadas normalmente
            resultado << linha
          end
        end

        # Retorna o texto reconstruído sem duplicatas
        resultado.join
      end

      # Gera uma versão canônica (normalizada) do passo para facilitar
      # a identificação de duplicatas mesmo com variações menores de texto.
      #
      # Exemplo: Dado "usuario" fez login  e Dado <usuario> fez login
      # gerarão o mesmo canonical para evitar repetição.
      #
      # Passos:
      # - Remove a keyword (Given, When, etc) do começo
      # - Substitui textos entre aspas, placeholders <> e números por <param>
      # - Remove acentuação e pontuação para normalizar
      # - Converte para minúsculas e remove espaços extras
      #
      # Parâmetros:
      # - linha: string com o passo completo
      # - keywords: array com as keywords para remoção
      #
      # Retorna uma string normalizada representando o passo
      def self.canonicalize_step(linha, keywords)
        texto = linha.dup.strip

        # Remove a keyword do início, se existir
        keywords.each do |kw|
          texto.sub!(/^#{kw}\s+/i, '')
        end

        # Substitui textos entre aspas, placeholders e números por <param>
        texto.gsub!(/"[^"]*"|<[^>]*>|\b\d+\b/, '<param>')

        # Remove acentos usando Unicode Normalization Form KD (decompõe caracteres)
        texto = Unicode.normalize_KD(texto).gsub(/\p{Mn}/, '')

        # Remove pontuação, deixando apenas letras, números, espaços e <>
        texto.gsub!(/[^a-zA-Z0-9\s<>]/, '')

        # Converte para minúsculas, remove espaços extras e retorna
        texto.downcase.strip.squeeze(" ")
      end
    end
  end
end
