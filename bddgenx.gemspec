require_relative "lib/bddgenx/version"

Gem::Specification.new do |spec|
  spec.name           = "bddgenx"
  spec.version        = Bddgenx::VERSION
  spec.add_dependency  "prawn", ">= 2.0"
  spec.add_dependency  "prawn-table", ">= 2.0"
  spec.add_dependency  "prawn-svg", ">= 2.0"
  spec.authors        = ["David Nascimento"]
  spec.email          = ["halison700@gmail.com"]

  spec.summary        = %q{Geração automática de BDD a partir de histórias de usuário}
  spec.description    = %q{Transforma arquivos .txt com histórias em arquivos .feature, com steps, rastreabilidade e integração com CI/CD.}
  spec.homepage       = "https://github.com/David-Nascimento/bdd-generation"
  spec.license        = "MIT"

  spec.files          = Dir["lib/**/*", "assets/fonts/**/*.{ttf,otf}"] + ["VERSION", "README.md", "Rakefile"]

  spec.bindir         = "bin"
  spec.executables    = ["bddgenx"]
  spec.require_paths  = ["lib"]

  spec.required_ruby_version = ">= 3.x"
end
