require_relative "lib/bddgenx"

Gem::Specification.new do |spec|
  spec.name           = "bddgenx"
  spec.version        = Bddgenx::VERSION
  spec.add_runtime_dependency  "prawn", ">= 2.0"
  spec.add_runtime_dependency  "prawn-table", ">= 0.2.0"
  spec.add_runtime_dependency  "prawn-svg", ">= 0.2.2"
  spec.add_runtime_dependency  "dotenv", ">= 3.1"

  spec.add_runtime_dependency  "ruby-openai", ">= 8.0" # ChatGPT
  spec.add_runtime_dependency  "faraday", ">= 2.13.0" # Gemini
  spec.add_runtime_dependency "unicode", "~> 0.4"
  spec.add_runtime_dependency 'yard', '~> 0.9.37'
  spec.add_runtime_dependency 'java_properties'

  spec.authors        = ["David Nascimento"]
  spec.email          = ["halison700@gmail.com"]

  spec.summary        = %q{Geração automática de BDD a partir de histórias de usuário}
  spec.description    = %q{Transforma arquivos .txt com histórias em arquivos .feature, com steps, rastreabilidade e integração com CI/CD.}
  spec.homepage       = "https://github.com/David-Nascimento/bdd-generation"
  spec.license        = "MIT"

  spec.files          = Dir["lib/**/*", "assets/fonts/**/*.{ttf,otf}"] + ["VERSION", "README.md"]

  spec.bindir         = "bin"
  spec.executables    = ["bddgenx"]
  spec.require_paths  = ["lib"]

  spec.required_ruby_version = ">= 3.x"
end
