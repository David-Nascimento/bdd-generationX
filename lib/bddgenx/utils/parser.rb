# lib/bddgenx/parser.rb
# encoding: utf-8
#
# Este arquivo define a classe Parser, responsável por ler e interpretar
# arquivos de história (.txt), extraindo cabeçalho e blocos de passos e exemplos.
# Utiliza constantes para identificação de tipos de blocos e suporta idiomas
# Português e Inglês na marcação de idioma e blocos de exemplos.

module Bddgenx
  # Tipos de blocos reconhecidos na história (.txt), incluindo variações em Português
  # e Inglês para blocos de exemplo.
  # @return [Array<String>]
  TIPOS_BLOCOS = %w[
    CONTEXT SUCCESS FAILURE ERROR EXCEPTION
    VALIDATION PERMISSION EDGE_CASE PERFORMANCE
    EXEMPLO EXEMPLOS RULE
  ].freeze

  # Parser de arquivos de história, converte .txt em estrutura de hash
  # com elementos :como, :quero, :para, :idioma e lista de :grupos.
  class Parser
    # Lê e analisa um arquivo de história, retornando um Hash com a estrutura:
    # {
    #   como:       String ou nil,
    #   quero:      String ou nil,
    #   para:      String ou nil,
    #   idioma:     'pt' ou 'en',
    #   grupos: [
    #     {
    #       tipo:     String (tipo de bloco),
    #       tag:      String ou nil (tag opcional após o bloco),
    #       passos:   Array<String> (linhas de passo),
    #       exemplos: Array<String> (linhas de exemplo)
    #     },
    #     ...
    #   ]
    # }
    #
    # @param caminho_arquivo [String] Caminho para o arquivo .txt de história
    # @raise [Errno::ENOENT] Se o arquivo não for encontrado
    # @return [Hash] Estrutura da história pronta para geração de feature
    def self.ler_historia(caminho_arquivo)
      # Carrega linhas do arquivo, preservando linhas vazias e encoding UTF-8
      linhas = File.readlines(caminho_arquivo, encoding: 'utf-8').map(&:rstrip)

      # Detecta idioma no topo do arquivo: suporta '# lang: <codigo>' ou '# language: <codigo>'
      idioma = 'pt'
      if linhas.first =~ /^#\s*lang(?:uage)?\s*:\s*(\w+)/i
        idioma = Regexp.last_match(1).downcase
        linhas.shift
      end

      # Extrai cabeçalho: linhas que começam com Como/Quero/Para (variações PT/EN)
      como, quero, para = nil, nil, nil
      linhas.reject! do |l|
        if l =~ /^\s*(?:como|eu como|as a)/i && como.nil?
          como = l
          true
        elsif l =~ /^\s*(?:quero|eu quero|quero que)/i && quero.nil?
          quero = l
          true
        elsif l =~ /^\s*(?:para|para eu|para que)/i && para.nil?
          para = l
          true
        else
          false
        end
      end

      # Inicializa estrutura da história
      historia = {
        como:   como,
        quero:  quero,
        para:   para,
        idioma: idioma,
        grupos: []
      }
      exemplos_mode = false

      # Processa cada linha restante para blocos e exemplos
      linhas.each do |linha|
        # Início de bloco de exemplos: [EXEMPLO], [EXEMPLOS] ou [EXAMPLES] com tag opcional
        if linha =~ /^\[(?:EXEMPLO|EXEMPLOS|EXAMPLES)\](?:@(\w+))?$/i
          exemplos_mode = true
          # Cria array de exemplos no último grupo, se ainda não existir
          historia[:grupos].last[:exemplos] = []
          next
        end

        # Início de bloco com tipo definido em TIPOS_BLOCOS e tag opcional
        if linha =~ /^\[(#{TIPOS_BLOCOS.join('|')})\](?:@(\w+))?$/i
          exemplos_mode = false
          tipo = Regexp.last_match(1).upcase
          tag  = Regexp.last_match(2)
          historia[:grupos] << { tipo: tipo, tag: tag, passos: [], exemplos: [] }
          next
        end

        # Atribui linha ao último bloco, como passo ou exemplo conforme modo
        next if historia[:grupos].empty?
        bloco = historia[:grupos].last
        if exemplos_mode
          bloco[:exemplos] << linha
        else
          bloco[:passos]   << linha
        end
      end

      historia
    end
  end
end
