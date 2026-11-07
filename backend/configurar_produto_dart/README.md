# Configurar_Produto (Dart)

Microsserviço do Velato Flow responsável pelo **catálogo de produtos**. Foi
escrito em Dart com [Shelf](https://pub.dev/packages/shelf) e organizado em
camadas, seguindo a apostila Back End com Dart. Substitui a versão Node do
1º semestre (`backend/Configurar_Produto`), mantendo as mesmas rotas.

## O que o serviço faz

| Rota | Resposta |
|---|---|
| `GET /produtos` | `200` com a lista de produtos do banco `BD_Produtos` |
| `POST /produtos` | `201` com o produto criado. Corpo: `{"nome": "...", "preco": 199.9}` |
| `GET /health/live` | `200` se o processo está de pé (não consulta o banco) |
| `GET /health/ready` | `200` se o banco responde; `503` se não responde |

- **Validação:** o nome precisa ter de 1 a 100 caracteres e o preço precisa ser
  maior que zero. Os erros voltam todos juntos, no formato
  `application/problem+json`.
- **Evento:** depois de salvar um produto, o serviço publica o evento
  `ProdutoCriado` no barramento. O Criar_Pedido e o Dashboard usam esse evento
  para atualizar a cópia do catálogo que cada um tem.
- **Kubernetes:** as rotas `/health` estão ligadas às probes de liveness e
  readiness em `backend/Kubernetes/configurar-produto-deployment.yaml`.
- Na partida, o serviço espera o banco ficar disponível (até 60 s) e, ao
  receber SIGTERM, fecha o servidor e o pool de conexões antes de sair.

## Organização das pastas

```
bin/server.dart            ponto de entrada: lê a configuração, espera o banco e sobe o servidor
lib/src/
  api.dart                 monta as rotas e os middlewares e injeta as dependências
  config/                  configuração (.env validado) e pool de conexões com o MySQL
  core/                    erros do domínio (validação, requisição inválida)
  models/                  classe Produto (fromJson / toJson)
  repositories/            acesso ao banco: interface + implementação MySQL
  services/                regras de negócio e publicação de eventos no barramento
  controllers/             tradução HTTP <-> domínio (produtos e health)
  web/                     middlewares (log, CORS, erros) e respostas problem+json
test/                      testes do ProdutoService com repositório e barramento falsos
```

Cada camada só conhece a de baixo: o controller chama o service, e o service
chama o repository. Por isso as regras de negócio podem ser testadas sem
HTTP e sem MySQL.

## Rodar localmente

Requisitos: Dart 3.13.7 ou mais novo (vem junto com o Flutter) e um MySQL com
o banco `BD_Produtos` (veja `backend/MySQL/01-setup_bancos.sql`).

```
cp .env.example .env        # no PowerShell: copy .env.example .env
# edite o .env com a senha do seu MySQL
dart pub get
dart run bin/server.dart
```

O serviço sobe em `http://localhost:3001`. No Kubernetes, os valores do `.env`
vêm das variáveis do Deployment.

## Testes e análise

```
dart test        # esperado: +6: All tests passed!
dart analyze     # regras em analysis_options.yaml (seção 2.5 da apostila)
```

## Docker

```
docker build -t configurar-produto-dart:latest .
```

A imagem é construída em dois estágios: o primeiro compila o servidor para
um executável nativo, e o segundo copia só esse executável para uma imagem
mínima.
