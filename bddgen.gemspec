Gem::Specification.new do |spec|
  spec.name          = "bddgen"
  spec.version       = Bddgen::VERSION
  spec.authors       = ["David Nascimento"]
  spec.email         = ["halison700@gmail.com"]

  spec.summary       = %q{Geração automática de BDD a partir de histórias de usuário}
  spec.description   = %q{Transforma arquivos .txt com histórias em arquivos .feature, com steps, rastreabilidade e integração com CI/CD.}
  spec.homepage      = "https://github.com/David-Nascimento/bddgen"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["bddgen"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"
end
