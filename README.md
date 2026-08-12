# AI + DevOps Lab

Laboratório prático para estudar a utilização de **AI Agents em
operações DevOps e Infrastructure as Code**, começando pela integração
direta com AWS e, posteriormente, com Terraform.

O objetivo inicial não é construir uma plataforma de Platform
Engineering, mas **entender as fundações e os padrões de interação entre
Agent, MCP, Terraform, AWS e posteriormente CI/CD**.

------------------------------------------------------------------------

## Objetivo atual

Construir e comparar dois cenários:

### Cenário 1 --- MCP direto na AWS

``` text
User
  ↓
Claude Code
  ↓
AWS MCP Server
  ↓
AWS APIs
  ↓
AWS
```

### Cenário 2 --- MCP + Terraform

``` text
User
  ↓
Claude Code
  ↓
Terraform MCP Server
  ↓
Terraform
  ↓
AWS Provider
  ↓
AWS
```

O objetivo é entender claramente a diferença entre:

-   Agent utilizando diretamente uma API/serviço;
-   Agent utilizando Terraform como camada de IaC;
-   MCP fornecendo ferramentas e contexto para o Agent.

------------------------------------------------------------------------

# Ambiente

## Hardware / OS

Ambiente local Linux.

Projeto:

``` text
/home/oem/Documents/projects/mcp-platform-engineering
```

------------------------------------------------------------------------

# Requisitos

## Claude Code

Versão utilizada:

``` bash
claude --version
```

Resultado:

``` text
2.1.224 (Claude Code)
```

------------------------------------------------------------------------

## AWS CLI

Versão utilizada:

``` bash
aws --version
```

Resultado:

``` text
aws-cli/2.36.17
```

------------------------------------------------------------------------

## Terraform

Versão utilizada:

``` bash
terraform version
```

Terraform:

``` text
1.15
```

------------------------------------------------------------------------

## Docker

Versão utilizada:

``` bash
docker --version
```

Docker:

``` text
29.7.2
```

Docker Engine:

``` text
29.7.2
```

------------------------------------------------------------------------

# Checkpoint 0 --- Preparação

## Objetivo

Validar que o ambiente local possui:

-   Claude Code
-   AWS CLI
-   Terraform
-   Docker
-   autenticação AWS

### Validação Claude Code

``` bash
claude --version
```

### Validação AWS CLI

``` bash
aws --version
```

### Validação Terraform

``` bash
terraform version
```

### Validação Docker

``` bash
docker --version
```

### Validação AWS

``` bash
aws sts get-caller-identity
```

Resultado utilizado no laboratório:

``` json
{
    "Account": "XXXXXXXXXXXX",
    "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/claude-user"
}
```

> As credenciais e informações reais da conta não devem ser armazenadas
> neste README.

### Status

**Checkpoint 0 --- OK**

------------------------------------------------------------------------

# Cenário 1 --- AWS MCP

## Objetivo

Permitir que o Claude Code consulte e opere recursos AWS utilizando um
MCP Server.

Fluxo:

``` text
Claude Code
     ↓
AWS MCP Server
     ↓
AWS APIs
     ↓
AWS Account
```

------------------------------------------------------------------------

# AWS Agent Toolkit

Foi utilizado o AWS Agent Toolkit para configurar a integração do Claude
Code com os recursos de AI da AWS.

Comando utilizado:

``` bash
aws configure agent-toolkit
```

O toolkit instalou/configurou diversas AWS Agent Skills globalmente.

Local:

``` text
~/.claude/skills/
```

Exemplos:

``` text
amazon-bedrock/
aws-auth/
aws-billing-and-cost-management/
aws-containers/
aws-deployment/
aws-observability/
aws-security/
aws-serverless/
...
```

Essas Skills ficam em nível global e não fazem parte do repositório do
laboratório.

------------------------------------------------------------------------

# Problema encontrado --- AWS MCP

Após a configuração inicial, o Claude Code apresentava:

``` text
aws-mcp x failed
```

As AWS Skills estavam disponíveis, porém o AWS MCP Server não estava
conectado.

O próprio Claude Code foi utilizado para realizar o troubleshooting e
corrigir a instalação/configuração.

Após a correção:

``` text
aws-mcp ✓ connected
```

### Aprendizado

O próprio Agent pode auxiliar no diagnóstico da infraestrutura
necessária para que suas próprias ferramentas funcionem.

------------------------------------------------------------------------

# Checkpoint 1.1 --- AWS MCP conectado

Status:

**OK**

Validação:

``` text
Claude Code
    ↓
AWS MCP
    ↓
Connected
```

------------------------------------------------------------------------

# Checkpoint 1.2 --- Consulta AWS

Foi realizado um teste read-only.

Solicitação ao Claude:

``` text
List my AWS VPCs and show their VPC IDs, CIDR blocks and states.
```

O Claude conseguiu consultar os recursos AWS utilizando o MCP.

Fluxo validado:

``` text
User
 ↓
Claude Code
 ↓
AWS MCP
 ↓
AWS API
 ↓
VPC information
```

### Status

**Checkpoint 1.2 --- OK**

------------------------------------------------------------------------

# Checkpoint 1.3 --- Operação de escrita

Foi realizado o primeiro teste de criação de recurso.

Solicitação:

``` text
Create an S3 bucket called "my-mcp-creation-test-part1",
make it private and configure a lifecycle of 10 days.
```

O Claude utilizou o AWS MCP para realizar a operação.

O recurso foi criado com:

-   nome definido;
-   configuração privada;
-   lifecycle configurado para 10 dias.

### Status

**Checkpoint 1.3 --- OK**

------------------------------------------------------------------------

# Cenário 1 --- Resultado

O primeiro cenário foi concluído com sucesso.

Arquitetura validada:

``` text
                 Claude Code
                     │
                     ▼
                AWS MCP Server
                     │
                     ▼
                  AWS API
                     │
                     ▼
                    AWS
```

O Agent foi capaz de:

-   consultar recursos AWS;
-   interpretar uma solicitação em linguagem natural;
-   executar operações AWS;
-   criar e configurar um recurso.

------------------------------------------------------------------------

# Cenário 2 --- Terraform MCP

## Objetivo

Introduzir Terraform como camada de Infrastructure as Code.

O objetivo é comparar:

``` text
Cenário 1

Claude
  ↓
AWS MCP
  ↓
AWS
```

com:

``` text
Cenário 2

Claude
  ↓
Terraform MCP
  ↓
Terraform
  ↓
AWS Provider
  ↓
AWS
```

------------------------------------------------------------------------

# Preparação do Terraform MCP

Inicialmente foi verificado que nenhum Terraform MCP estava configurado:

``` text
terraform-mcp não estava configurado
```

Foi escolhido o **Terraform MCP Server oficial da HashiCorp**.

A execução local foi escolhida utilizando Docker.

------------------------------------------------------------------------

# Problema encontrado --- Docker permissions

Durante a instalação do Terraform MCP, foi identificado que o usuário
não possuía acesso ao Docker Socket:

``` text
permission denied while trying to connect to the Docker API
at unix:///var/run/docker.sock
```

Foi verificado:

``` bash
getent group docker
```

Resultado:

``` text
docker:x:986:oem
```

O usuário já estava cadastrado no grupo `docker`, porém a sessão atual
não havia carregado o grupo.

Foi necessário realizar logout/login completo para que a sessão
carregasse corretamente a associação.

Validação:

``` bash
id
```

O grupo `docker` passou a aparecer na sessão.

Depois:

``` bash
docker ps
```

passou a funcionar sem `sudo`.

### Aprendizado

A associação do usuário ao grupo `docker` pode existir no sistema, mas a
sessão atual precisa carregar essa associação.

------------------------------------------------------------------------

# Instalação do Terraform MCP

O Terraform MCP Server foi configurado globalmente no Claude Code.

Comando utilizado:

``` bash
claude mcp add terraform -s user -t stdio -- docker run -i --rm hashicorp/terraform-mcp-server
```

Validação:

``` bash
claude mcp list
```

Resultado:

``` text
terraform ... Connected
```

### Status

**Checkpoint 2.2 --- OK**

------------------------------------------------------------------------

# Checkpoint 2.3 --- Descobrindo o Terraform MCP

Neste momento o projeto ainda não possui código Terraform.

Estrutura inicial:

``` text
mcp-platform-engineering/
└── pictures/
```

Foi solicitado ao Claude:

``` text
What Terraform MCP tools are available to you?
Explain briefly what each one does.
Don't execute anything.
```

O Claude identificou que as ferramentas disponíveis são principalmente
**read-only e relacionadas ao Terraform Registry**.

## Terraform MCP --- ferramentas observadas

### Providers

``` text
search_providers
get_provider_details
get_latest_provider_version
get_provider_capabilities
```

### Modules

``` text
search_modules
get_module_details
get_latest_module_version
```

### Policies

``` text
search_policies
get_policy_details
```

------------------------------------------------------------------------

# Descoberta importante --- Terraform MCP ≠ Terraform CLI

Durante o laboratório foi identificado que o Terraform MCP Server
utilizado **não é simplesmente um wrapper para executar comandos locais
como**:

``` bash
terraform plan
terraform apply
terraform validate
```

As ferramentas disponíveis estão principalmente relacionadas ao
**Terraform Registry**.

Isso cria uma distinção importante:

``` text
Terraform MCP
      │
      └── Terraform Registry
            ├── Providers
            ├── Modules
            └── Policies
```

Enquanto o Terraform CLI continua sendo responsável pela execução da
infraestrutura:

``` text
Terraform CLI
      │
      ▼
AWS Provider
      │
      ▼
AWS
```

### Status

**Checkpoint 2.3 --- OK**

------------------------------------------------------------------------

# Checkpoint 2.4 --- Consultando o Terraform Registry

Solicitação:

``` text
Find the latest version of the official AWS Terraform provider
and show me the documentation for creating an S3 bucket.
Do not create or modify anything.
```

O Claude retornou:

``` text
hashicorp/aws — v6.58.0
```

Também apresentou a documentação atual do recurso:

``` text
aws_s3_bucket
```

Entre as informações retornadas estavam:

-   versão atual do provider;
-   estrutura mínima do recurso;
-   uso de `bucket`;
-   `bucket_prefix`;
-   `force_destroy`;
-   informações de import;
-   recursos dedicados para lifecycle;
-   recursos dedicados para public access;
-   deprecated inline arguments.

### Descoberta

O MCP permite que o Agent consulte informações atuais do Terraform
Registry antes de gerar código.

Fluxo validado:

``` text
Claude
   ↓
Terraform MCP
   ↓
Terraform Registry
   ↓
AWS Provider Documentation
```

### Status

**Checkpoint 2.4 --- OK**

------------------------------------------------------------------------

# Checkpoint 2.5 --- Geração do primeiro código Terraform

Após consultar a documentação atual do provider, foi solicitado ao
Claude:

``` text
Create a minimal Terraform configuration for an S3 bucket using the current AWS provider documentation you just retrieved. The bucket should be private and have a lifecycle configuration that expires objects after 10 days. Do not run Terraform or create any AWS resources.
```

O Claude criou:

``` text
main.tf
```

A configuração utilizou:

-   `hashicorp/aws ~> 6.0`;
-   `aws_s3_bucket`;
-   `aws_s3_bucket_public_access_block`;
-   `aws_s3_bucket_lifecycle_configuration`;
-   variável `bucket_name`;
-   lifecycle de 10 dias.

Nenhum comando Terraform foi executado e nenhum recurso AWS foi criado
neste checkpoint.

## Validação do uso do Terraform MCP

Foi realizado um teste adicional para confirmar que o MCP havia sido
efetivamente utilizado.

Solicitação:

``` text
Use the Terraform MCP to look up the current documentation for aws_s3_bucket_lifecycle_configuration. Do not modify files, run Terraform, or use external web search. Afterward, tell me which Terraform MCP tools you called.
```

O Claude informou as seguintes chamadas:

``` text
1. search_providers
2. get_provider_details
```

Fluxo observado:

``` text
search_providers
       ↓
providerDocID
       ↓
get_provider_details
       ↓
Terraform Registry
       ↓
Claude
```

Provider:

``` text
hashicorp/aws
```

Versão consultada:

``` text
6.58.0
```

### Descoberta importante

O resultado correto do código, por si só, não prova que o MCP foi
utilizado.

A confirmação foi feita observando as **Tool Calls** realizadas pelo
Claude.

Isso permite distinguir:

``` text
"Claude sabe gerar Terraform"
```

de:

``` text
"Claude utilizou o Terraform MCP
para consultar informações atuais
antes de gerar Terraform."
```

### Status

**Checkpoint 2.5 --- OK**

------------------------------------------------------------------------

# Checkpoint 2.6 --- Terraform CLI / Validate

Foi solicitado ao Claude:

``` text
Review the Terraform configuration you just created. Run terraform fmt and terraform validate. Do not run plan or apply, and do not create or modify any AWS resources.
```

O Claude executou comandos através da capacidade de **Shell** do Claude
Code.

### Comandos executados

``` bash
terraform fmt -diff -recursive
terraform init -backend=false
terraform validate
```

O `terraform init` foi necessário para baixar o provider e permitir que
o `terraform validate` verificasse os schemas.

### Resultado

``` text
terraform fmt
→ no diff

terraform validate
→ Success! The configuration is valid.
```

Foram criados localmente:

``` text
.terraform/
.terraform.lock.hcl
```

Nenhum recurso AWS foi criado ou alterado.

### Descoberta importante

O Terraform MCP não executou o `terraform validate`.

O fluxo foi:

``` text
Claude Code
    ↓
Shell
    ↓
Terraform CLI
```

Enquanto o Terraform MCP permanece responsável pelas consultas ao
Terraform Registry.

### Status

**Checkpoint 2.6 --- OK**

------------------------------------------------------------------------

# Checkpoint 2.7 --- Terraform Plan → AWS

Foi criado um segundo bucket para manter os experimentos isolados do
Cenário 1:

``` text
my-mcp-terraform-test-part2
```

Foi solicitado ao Claude:

``` text
Run terraform plan using my-mcp-terraform-test-part2 as the bucket_name variable. Do not run apply.
```

O Terraform executou o plan com sucesso.

Resultado:

``` text
Plan: 3 to add, 0 to change, 0 to destroy.
```

Recursos planejados:

``` text
aws_s3_bucket.this
aws_s3_bucket_lifecycle_configuration.this
aws_s3_bucket_public_access_block.this
```

Região:

``` text
us-east-1
```

Nenhum recurso foi criado durante o `plan`.

### Fluxo validado

``` text
Claude Code
    │
    ├── Terraform MCP
    │      ↓
    │   Terraform Registry
    │
    └── Shell
           ↓
      Terraform CLI
           ↓
      AWS Provider
           ↓
          AWS
           ↓
     Terraform Plan
```

### Status

**Checkpoint 2.7 --- OK**

------------------------------------------------------------------------

# Checkpoint 2.8 --- Terraform Apply

Após a validação do `plan`, foi realizado o `terraform apply` do
ambiente de laboratório.

Resultado:

``` text
3 resources added
0 changed
0 destroyed
```

Recursos criados:

``` text
aws_s3_bucket.this
aws_s3_bucket_public_access_block.this
aws_s3_bucket_lifecycle_configuration.this
```

Bucket criado:

``` text
my-mcp-terraform-test-part2
```

Configurações:

-   bucket privado;
-   todos os quatro controles de Public Access Block habilitados;
-   lifecycle configurado para expirar objetos após 10 dias.

Região:

``` text
us-east-1
```

### Estado Terraform

Após o `apply`, o Terraform passou a controlar o estado da
infraestrutura através de:

``` text
terraform.tfstate
```

O state está atualmente armazenado localmente no projeto.

### Atenção

O `terraform.tfstate` pode conter informações sensíveis e **não deve ser
versionado inadvertidamente**.

Também foi identificado que o diretório `.terraform/` não deve ser
commitado, enquanto o:

``` text
.terraform.lock.hcl
```

normalmente deve ser versionado.

### Fluxo completo validado

``` text
                    Claude Code
                         │
             ┌───────────┴───────────┐
             │                       │
       Terraform MCP              Shell
             │                       │
             ▼                       ▼
    Terraform Registry        Terraform CLI
             │                       │
             │                       ▼
             │                  AWS Provider
             │                       │
             └───────────────────────┤
                                     ▼
                                    AWS
```

### Comparação com o Cenário 1

No Cenário 1:

``` text
Claude
  ↓
AWS MCP
  ↓
AWS API
  ↓
S3
```

No Cenário 2:

``` text
Claude
  ↓
Terraform MCP
  ↓
Terraform Registry
  ↓
Claude gera Terraform
  ↓
Terraform CLI
  ↓
AWS Provider
  ↓
AWS
```

A principal diferença é que no Cenário 2 a infraestrutura passa a ser
representada por **Infrastructure as Code e Terraform State**,
permitindo uma abordagem declarativa e rastreável.

### Status

**Checkpoint 2.8 --- OK**

------------------------------------------------------------------------

# Cenário 2 --- Resultado

O Cenário 2 foi concluído com sucesso.

O Agent foi capaz de:

-   consultar documentação atual do Terraform Registry;
-   consultar versões do provider;
-   gerar código Terraform;
-   validar o código;
-   executar `terraform plan`;
-   executar `terraform apply`;
-   criar infraestrutura AWS através do Terraform;
-   manter o estado da infraestrutura através do Terraform State.

O laboratório também demonstrou que **MCP e Terraform CLI possuem
responsabilidades diferentes**.

O Terraform MCP fornece principalmente **conhecimento e acesso ao
ecossistema Terraform**, enquanto o Terraform CLI realiza as operações
de IaC.

------------------------------------------------------------------------

# Roadmap

## Cenário 1 --- AWS MCP

-   [x] Checkpoint 0 --- Preparação
-   [x] Checkpoint 1.1 --- AWS MCP conectado
-   [x] Checkpoint 1.2 --- Consulta AWS
-   [x] Checkpoint 1.3 --- Criação de recurso AWS

## Cenário 2 --- Terraform MCP

-   [x] Checkpoint 2.1 --- Terraform MCP identificado
-   [x] Checkpoint 2.2 --- Terraform MCP conectado
-   [x] Checkpoint 2.3 --- Descoberta das ferramentas
-   [x] Checkpoint 2.4 --- Consultar Terraform Registry
-   [x] Checkpoint 2.5 --- Gerar primeiro código Terraform
-   [x] Checkpoint 2.6 --- Terraform CLI / Validate
-   [x] Checkpoint 2.7 --- Terraform Plan → AWS
-   [x] Checkpoint 2.8 --- Terraform Apply

## Cenário 3 --- Pipeline

-   [ ] GitHub MCP
-   [ ] Repositório Terraform
-   [ ] GitHub Actions
-   [ ] Pipeline Terraform
-   [ ] Agent → Pull Request
-   [ ] Agent → Pipeline
-   [ ] Plan automático

## Evolução futura

-   [ ] EKS
-   [ ] Kubernetes MCP
-   [ ] Observabilidade
-   [ ] Security
-   [ ] Architecture explanation
-   [ ] Skills específicas
-   [ ] Commands
-   [ ] Hooks
-   [ ] Golden Paths conversacionais
-   [ ] Platform Engineering Assistant

------------------------------------------------------------------------

# Princípios do laboratório

1.  **Não pular etapas.**
2.  Primeiro entender o conceito, depois automatizar.
3.  Começar com operações read-only sempre que possível.
4.  Separar Agent, MCP, ferramentas e infraestrutura.
5.  Não confundir MCP com Terraform ou AWS API.
6.  Não construir a plataforma antes de entender as fundações.
7.  Mudanças destrutivas devem exigir supervisão humana.
8.  Documentar descobertas e problemas encontrados durante o
    laboratório.
9.  Observar as Tool Calls quando for necessário comprovar qual
    ferramenta o Agent utilizou.
10. Separar conhecimento/contexto de execução de infraestrutura.

------------------------------------------------------------------------

# Conceito central

O laboratório busca entender a evolução:

``` text
AI Agent
   ↓
MCP
   ↓
Tools
   ↓
DevOps capabilities
   ↓
Infrastructure
   ↓
Automation
   ↓
Platform Engineering
```

O objetivo final não é simplesmente "usar IA para escrever Terraform".

É entender como um Agent pode **utilizar ferramentas e processos de
engenharia de forma segura, reproduzível e governada**.


---

# Cenário 3 — GitHub MCP

## Objetivo

Introduzir o GitHub como parte do ambiente de trabalho do Agent.

O objetivo é permitir que o Claude Code interaja com o repositório do laboratório através do GitHub MCP.

Fluxo inicial:

```text
Claude Code
     ↓
GitHub MCP Server
     ↓
GitHub API
     ↓
Repository
```

---

# Checkpoint 3.1 — GitHub MCP conectado

Inicialmente foi verificado que o GitHub MCP não estava configurado para o projeto.

Foi configurado o **GitHub MCP Server** utilizando um Personal Access Token (PAT) armazenado em variável de ambiente.

O token não é armazenado no repositório nem no README.

Validação:

```text
github ✓ Connected
```

O Claude Code passou a apresentar os seguintes MCPs conectados:

```text
context7      ✓ Connected
aws-mcp       ✓ Connected
terraform     ✓ Connected
github        ✓ Connected
```

### Status

**Checkpoint 3.1 — OK**

---

# Checkpoint 3.2 — Claude → GitHub Read-Only

Foi realizado o primeiro teste de interação com o repositório através do GitHub MCP.

Solicitação ao Claude:

```text
Inspect the GitHub repository for this project. Tell me its repository name, default branch, current files, and the latest commit. Do not modify anything.
```

O Claude conseguiu consultar o repositório e retornar suas informações sem realizar alterações.

Fluxo validado:

```text
User
 ↓
Claude Code
 ↓
GitHub MCP
 ↓
GitHub API
 ↓
Repository information
```

### Descoberta importante

Assim como no Terraform MCP, a confirmação de que o MCP foi efetivamente utilizado deve ser feita observando as **Tool Calls** realizadas pelo Agent, e não apenas pelo resultado final.

O resultado correto, por si só, não é suficiente para provar qual ferramenta foi utilizada.

### Status

**Checkpoint 3.2 — OK**

---

# Próximo passo — Checkpoint 3.3

O próximo objetivo será permitir que o Claude trabalhe efetivamente com o conteúdo versionado no GitHub.

Primeiro exercício planejado:

```text
Inspect the README.md in the GitHub repository and identify
what has changed since the current local project version.
Do not modify anything.
```

Depois disso, o laboratório evoluirá para operações controladas de escrita:

```text
Claude
  ↓
GitHub MCP
  ↓
GitHub
  ↓
Commit / Branch / Pull Request
```

Ainda não será introduzido GitHub Actions.

O objetivo primeiro é entender claramente como o Agent interage com o repositório antes de transformar o GitHub em parte do fluxo de CI/CD.