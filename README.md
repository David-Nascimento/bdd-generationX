# 🧪 Gerador de BDD Automático em Ruby

Este projeto gera arquivos `.feature` (formato Gherkin) automaticamente a partir de arquivos `.txt` contendo histórias de usuário. Ele segue as práticas do ISTQB e suporta múltiplos tipos de cenários, contexto, regras de negócio e exemplos estruturados.

---

## 📂 Estrutura do Projeto

```
bdd_generator/
├── bin/
│ └── bddgen # Script executável
├── input/ # Arquivos .txt com histórias
├── features/ # Arquivos .feature gerados
├── steps/ # Step definitions automáticos
├── output/
│ └── rastreabilidade.csv # Rastreabilidade dos testes
├── backup/ # Backups das versões antigas dos .feature
├── lib/
│ ├── cli.rb
│ ├── parser.rb
│ ├── validator.rb
│ ├── generator.rb
│ ├── steps_generator.rb
│ ├── tracer.rb
│ └── backup.rb
├── main.rb # Arquivo principal
└── Rakefile # Execução via rake gerar_bdd
```
---

## ▶️ Como Executar

### ✅ Requisitos:
- Ruby 3.x ou superior

### 🚀 Execução direta:
```bash
ruby main.rb
```

### 🚀 Com script:
```bash
./bin/bddgen
```

### 🚀 Com Rake:
```bash
rake gerar_bdd
```


### ✍️ Como Criar um Arquivo .txt de Entrada:
Exemplo: input/login.txt
```txt
Como um usuário do sistema
Quero fazer login
Para acessar meus dados pessoais

[CONTEXT]
Dado que estou na página inicial

[REGRA]
Apenas usuários com conta podem acessar

[SUCCESS]
Dado que informo credenciais válidas
Quando clico em "Entrar"
Então vejo minha área privada

[FAILURE]
Dado que informo senha incorreta
Quando clico em "Entrar"
Então vejo uma mensagem de erro

[EXAMPLES]
| email              | senha        | resultado               |
| user@email.com     | correta123   | acesso liberado         |
| user@email.com     | errada456    | erro de autenticação    |

```
### 🌐 Idiomas Suportados:
Adicione no topo do .txt:
```txt
# lang: en
```
Para gerar arquivos em inglês (Scenario, Given, Then, etc.).

### 🏷️ Tipos de Cenário Suportados:
- [SUCCESS] – Teste Positivo

- [FAILURE] – Teste Negativo

- [ERROR] – Erros inesperados

- [EXCEPTION] – Exceções e falhas técnicas

- [VALIDATION] – Validação de campos

- [PERMISSION] – Permissões e acesso

- [EDGE_CASE] – Casos limite

- [PERFORMANCE] – Testes de carga ou volume

- [CONTEXT] – Passos comuns a todos os cenários

- [REGRA] – Regras de negócio

- [EXAMPLES] – Cenários com dados variados

### 📊 Rastreabilidade:
Ao gerar um .feature, o sistema adiciona uma linha no arquivo:
```sh
output/rastreabilidade.csv
```
Com colunas:
- Funcionalidade
- Tipo de Teste
- Nome do Cenário
- Caminho do arquivo .feature

### 🔐 Backup Automático:
Antes de sobrescrever um arquivo .feature, o sistema salva uma cópia em:
```
backup/
```
Com timestamp no nome, ex:
```
login_20250510_153001.feature
```
### ⚙️ CI/CD:
Exemplo para GitHub Actions:
```yaml
jobs:
  gerar_bdd:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
      - run: ruby main.rb

```

### 👨‍💻 Autor:
David Nascimento – Gerador de BDD com Ruby e Gherkin – 2025
```yaml 
Esse README já está pronto para ser usado em repositórios, arquivos `.zip` ou documentação interna da sua equipe.

Posso te ajudar agora a montar um `.zip` com todos os arquivos prontos?

```