#!/usr/bin/env ruby
require_relative 'bddgenx/runner'

# Só executa quando este arquivo for o entrypoint, não no require da gem
if __FILE__ == $PROGRAM_NAME
  Bddgenx::Runner.execute
end
