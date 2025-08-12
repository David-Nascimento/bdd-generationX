require_relative 'env'

# Carrega o arquivo 'env.rb' relativo a este script. Geralmente contém configurações e carregamento da gem Bddgenx.

## Evita warns na saida do console
Gem::Specification.reset
# Reseta as especificações das gems carregadas para evitar warnings no console, comum em alguns ambientes Ruby.

# Só executa o código abaixo quando este arquivo for o ponto de entrada (entrypoint) da aplicação,
# evitando que o código seja executado quando este arquivo for apenas requerido por outro arquivo.
if __FILE__ == $PROGRAM_NAME
  Bddgenx::Runner.execute
  # Invoca o método principal da gem Bddgenx para iniciar a execução da ferramenta.
end
