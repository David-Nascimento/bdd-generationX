# language: pt
Funcionalidade: adicionar produtos ao carrinho

  Como um cliente do e-commerce
  Quero adicionar produtos ao carrinho
  Para finalizar minha compra com praticidade

    Regra: O carrinho não deve permitir produtos fora de estoque
      E o valor total deve refletir o desconto promocional

    Contexto:
      Dado que estou logado na plataforma
      E tenho produtos disponíveis

    @success
    Cenário: Teste Positivo - adiciono um produto ao carrinho - vejo o total <total esperado>
      Quando adiciono um produto ao carrinho
      Então ele aparece na listagem do carrinho
      Quando adiciono "<produto>" com quantidade <quantidade>
      Então vejo o total <total esperado>

    @failure
    Cenário: Teste Negativo - tento adicionar um produto esgotado - recebo uma mensagem de "produto indisponível"
      Quando tento adicionar um produto esgotado
      Então recebo uma mensagem de "produto indisponível"

    @error
    Cenário: Teste de Erro - o serviço de estoque estiver fora do ar - exibo uma mensagem de erro técnico
      Quando o serviço de estoque estiver fora do ar
      Então exibo uma mensagem de erro técnico

    @exception
    Cenário: Teste de Exceção - o produto estiver com dados inconsistentes - o sistema deve registrar o erro e impedir a adição
      Quando o produto estiver com dados inconsistentes
      Então o sistema deve registrar o erro e impedir a adição

    @validation
    Cenário: Teste de Validação - tento adicionar uma quantidade negativa - exibo uma mensagem de validação
      Quando tento adicionar uma quantidade negativa
      Então exibo uma mensagem de validação

    @permission
    Cenário: Teste de Permissão - um usuário não logado tenta adicionar um produto - sou redirecionado para a tela de login
      Quando um usuário não logado tenta adicionar um produto
      Então sou redirecionado para a tela de login

    @edge_case
    Cenário: Teste de Limite - adiciono 999 unidades de um item - o sistema limita automaticamente a 10 unidades
      Quando adiciono 999 unidades de um item
      Então o sistema limita automaticamente a 10 unidades

    @performance
    Cenário: Teste de Desempenho - adiciono 100 produtos seguidos - o tempo de resposta deve ser inferior a 2 segundos
      Quando adiciono 100 produtos seguidos
      Então o tempo de resposta deve ser inferior a 2 segundos

    Esquema do Cenário: Gerado a partir de dados de exemplo
      Quando adiciono "<produto>" com quantidade <quantidade>
      Então vejo o total <total esperado>

      Exemplos:
        | produto        | quantidade | total esperado |
        | Camiseta Azul  | 2          | 100            |
        | Tênis Branco   | 1          | 250            |
