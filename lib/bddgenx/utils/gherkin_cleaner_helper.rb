module Bddgenx
  module Utils
    # Método principal para limpar o texto Gherkin recebido.
    # Executa uma sequência de operações para deixar o texto formatado e correto.
    #
    # Passos:
    # - Remove blocos de código markdown (```).
    # - Garante que exista somente uma linha # language: correta.
    # - Corrige a indentação dos blocos Gherkin para o padrão esperado.
    # - Remove espaços em branco no início/fim do texto.
    #
    # Retorna o texto limpo e formatado.
    def self.limpar(texto)
      texto = remover_blocos_markdown(texto)
      texto = corrigir_language(texto)
      texto = corrigir_indentacao(texto)
      texto.strip
    end

    # Remove blocos markdown que usam as crases tripas (```).
    # Muitas vezes a IA retorna os textos dentro desses blocos, que precisam ser limpos.
    #
    # Exemplo:
    # ```gherkin
    # Feature: Exemplo
    # ```
    #
    # Essa função remove as linhas contendo as crases, deixando só o conteúdo.
    def self.remover_blocos_markdown(texto)
      texto.gsub(/```[a-z]*\n?/i, '').gsub(/```/, '')
    end

    # Garante que o arquivo contenha exatamente uma linha "# language: xx" no topo.
    #
    # Passos:
    # - Procura a primeira ocorrência da linha de language no texto.
    # - Remove todas as outras linhas duplicadas de language.
    # - Se encontrar, move essa linha para o início do texto.
    # - Se não encontrar, detecta o idioma do texto e adiciona a linha no topo.
    #
    # Isso evita erros de parsing em ferramentas BDD que exigem essa diretiva.
    def self.corrigir_language(texto)
      linhas = texto.lines
      primeira_language = linhas.find { |linha| linha.strip.start_with?('# language:') }

      # Remove todas as linhas duplicadas de language
      linhas.reject! { |linha| linha.strip.start_with?('# language:') }

      if primeira_language
        # Insere a linha de language original no topo
        linhas.unshift(primeira_language.strip + "\n")
      else
        # Se não existir, detecta o idioma e insere padrão
        idioma = detectar_idioma(linhas.join)
        linhas.unshift("# language: #{idioma}\n")
      end

      linhas.join
    end

    # Detecta o idioma do conteúdo baseado nas palavras-chave Gherkin presentes.
    #
    # Retorna:
    # - 'pt' se encontrar palavras-chave em português (Dado, Quando, Então, E).
    # - 'en' se encontrar palavras-chave em inglês (Given, When, Then, And).
    # - 'pt' como padrão se não detectar.
    #
    # Isso ajuda a definir a diretiva # language: corretamente.
    def self.detectar_idioma(texto)
      return 'pt' if texto =~ /Dado|Quando|Então|E /i
      return 'en' if texto =~ /Given|When|Then|And /i
      'pt' # padrão
    end

    # Corrige a indentação das linhas para seguir o padrão Gherkin:
    #
    # Feature e Funcionalidade no nível 0 (sem indentação).
    # Scenario e Scenario Outline com 2 espaços.
    # Passos (Given, When, Then, And e equivalentes PT) com 4 espaços.
    # Tabelas (linhas que começam com '|') com 6 espaços.
    #
    # Outras linhas recebem indentação padrão de 2 espaços.
    #
    # Essa padronização melhora legibilidade e compatibilidade com parsers Gherkin.
    def self.corrigir_indentacao(texto)
      linhas = texto.lines.map do |linha|
        if linha.strip.start_with?('Feature', 'Funcionalidade')
          linha.strip + "\n"
        elsif linha.strip.start_with?('Scenario', 'Cenário', 'Scenario Outline', 'Esquema do Cenário')
          "  #{linha.strip}\n"
        elsif linha.strip.start_with?('Given', 'When', 'Then', 'And', 'Dado', 'Quando', 'Então', 'E')
          "    #{linha.strip}\n"
        elsif linha.strip.start_with?('|')
          "      #{linha.strip}\n"
        else
          "  #{linha.strip}\n"
        end
      end
      linhas.join
    end
  end
end
