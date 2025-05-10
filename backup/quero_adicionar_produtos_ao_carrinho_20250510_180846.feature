# language: pt
Funcionalidade: adicionar produtos ao carrinho

  Como um cliente do e-commerce
  Quero adicionar produtos ao carrinho
  Para finalizar minha compra com praticidade

    Regra: O carrinho não deve permitir produtos fora de estoque

    Regra: E o valor total deve refletir o desconto promocional

    Contexto:
      Dado que estou logado na plataforma
      E tenho produtos disponíveis

    Esquema do Cenário: Gerado a partir de dados de exemplo
      Quando adiciono "<produto>" com quantidade <quantidade>
      Então vejo o total <total esperado>

      Exemplos:
        | produto        | quantidade | total esperado |
        | Camiseta Azul  | 2          | 100            |
        | Tênis Branco   | 1          | 250            |
