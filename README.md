# Velato Flow — Controle seus pedidos, acelere suas vendas

**Projeto semestral das disciplinas ECM252 e ECM516 do IMT**

| RA | Nome completo |
|----|---------------|
| 23.00758-3 | Guilherme de Santana Pinto |
| 23.01409-0 | Maria Luiza Bogossian Remaili |
| 23.00977-2 | Rafaella Bataglia Dallovo |
| 23.00635-8 | Sarah Mascarese de Souza |

---

## Sobre o Velato Flow

Você já perdeu uma venda porque não sabia que o pedido ainda estava parado na separação? Já deixou um cliente sem resposta porque a planilha de controle estava desatualizada? Já descobriu que um pedido urgente estava perdido no meio de dezenas de outros porque não havia nenhuma forma de priorizá-lo?

O **Velato Flow** nasceu para acabar com esse caos.

Desenvolvido sob medida para a **Velato** — marca de calças com zíper oculto —, o Velato Flow é uma plataforma de gestão de pedidos que transforma a operação de e-commerce em um fluxo visual, inteligente e centralizado. Inspirado no método Kanban, utilizado pelas empresas mais eficientes do mundo, ele coloca cada pedido no lugar certo, na hora certa, na frente de quem precisa agir.

Chega de planilha. Chega de achismo. Chega de pedido perdido.

---

## Por que o Velato Flow vai mudar a sua operação?

### Agilidade do pedido à entrega
Cada pedido percorre um caminho visual e claro: do momento em que entra até o instante em que chega na mão do cliente. Sua equipe sabe exatamente o que precisa fazer — sem precisar perguntar, sem precisar checar, sem retrabalho.

### Foco no que é urgente
Pedidos com prioridade alta ganham destaque visual imediato e sobem automaticamente para o topo das listas. Nada urgente fica esquecido. Nunca mais.

### Decisões baseadas em dados reais
Um painel gerencial atualizado em tempo real mostra o que está acontecendo no seu negócio agora: quantos pedidos entraram hoje, quais produtos estão bombando, quantas entregas foram concluídas. Informação na hora certa para a decisão certa.

### Transparência total para o time
Todo movimento de um pedido fica registrado com data e horário. Quem fez o quê e quando. Seu time tem clareza, sua gestão tem controle, sua auditoria tem histórico.

---

## O que o Velato Flow oferece

### Quadro Kanban de Pedidos

O coração da plataforma. Visualize todos os seus pedidos organizados em cinco etapas operacionais:

**Recebido → Pagamento Confirmado → Separado → Enviado → Entregue**

Cada pedido aparece como um cartão no quadro, mostrando os produtos incluídos, o responsável pela operação e a prioridade. Avançar ou retroceder um pedido é tão simples quanto clicar em um botão.

**Criação rápida de pedidos:** Cadastre uma nova venda em segundos, escolhendo os produtos diretamente do catálogo e definindo quem é o responsável e qual a urgência do pedido.

**Filtros inteligentes:** Encontre qualquer pedido instantaneamente pelo nome do produto, pelo responsável ou pela prioridade. Em uma operação com dezenas de pedidos abertos, isso vale ouro.

**Histórico completo:** Consulte, diretamente no cartão do pedido, todo o caminho que ele percorreu — com datas e horários de cada movimentação. Transparência total do início ao fim.

---

### Painel Gerencial — Dashboard

Visão estratégica do seu negócio em tempo real, sem precisar abrir uma única planilha.

**Indicadores principais (KPIs):**
- Total de pedidos registrados
- Pedidos entregues hoje
- Pedidos urgentes aguardando ação
- Total de produtos cadastrados no catálogo

**Gráfico de volume dos últimos 7 dias:** Acompanhe o ritmo da sua operação dia a dia e antecipe picos de demanda antes que virem problema.

**Ranking dos produtos mais pedidos:** Descubra quais produtos lideram as vendas e tome decisões de estoque e reposição com base em dados reais — não em suposições.

---

### Velato Flow no celular

Sua operação não para quando você sai do computador — e o Velato Flow também não. O **app para celular** traz o quadro Kanban e o painel gerencial completos para a palma da mão:

- Acompanhe os pedidos em tempo real, de onde estiver.
- Cadastre produtos e crie pedidos na hora em que a venda acontece.
- Avance, retroceda ou cancele um pedido com um toque, com confirmação para evitar erros.
- Consulte o histórico de cada pedido e encontre qualquer um pela busca ou pela prioridade.
- Abra o painel gerencial com indicadores e gráficos, em uma tela pensada para o celular.

Tudo o que é feito no celular aparece no computador, e vice-versa: é o mesmo sistema, sempre sincronizado.

---

## Para quem é o Velato Flow?

Para qualquer negócio de e-commerce que está crescendo rápido demais para continuar gerindo pedidos no braço. Para equipes que precisam de clareza sobre o que está acontecendo sem parar para perguntar. Para gestores que querem dados — não achismos — na hora de tomar decisões.

Se você vende online e quer operar com a eficiência de uma grande empresa sem a complexidade de uma, o Velato Flow é para você.

---

*Velato Flow — porque faturar mais começa por errar menos.*

---

## Como o Velato Flow funciona por dentro

O sistema segue a **arquitetura de microsserviços**: cada parte do negócio é um serviço independente, com o seu próprio banco de dados. Os serviços conversam entre si por um **barramento de eventos** (ex.: "produto criado", "pedido movido"), então a queda de um não derruba os outros.

| Componente | Tecnologia | Responsabilidade | Banco |
|---|---|---|---|
| Configurar_Produto | **Dart** (shelf) | Catálogo de produtos | `BD_Produtos` |
| Criar_Pedido | Node.js (Express) | Criar, listar, mover e excluir pedidos | `KanBan` |
| Historico | Node.js (Express) | Registrar cada movimentação dos pedidos | `BD_Historico` |
| Dashboard | Node.js (Express) | Indicadores e gráficos do painel | `BD_DashBoard` |
| Barramento | Node.js (Express) | Repassar os eventos entre os serviços | — |
| Banco de dados | MySQL 8 | Cria os 4 bancos sozinho na primeira subida | — |
| App mobile | **Flutter** | Kanban + Dashboard no celular | — |
| Kanban web / Dashboard web | React | Kanban e painel no navegador | — |

Todo o Back End roda em **contêineres Docker** e é implantado no **Kubernetes**.

### Estrutura do repositório

```
backend/
  Barramento/  Criar_Pedido/  Historico/  Dashboard/   serviços Node.js (cada um com Dockerfile)
  configurar_produto_dart/                              serviço Configurar_Produto em Dart
  Configurar_Produto/                                   versão original em Node (Parte 1)
  MySQL/                                                imagem do banco + script de criação
  Kubernetes/                                           arquivos de implantação (.yaml)
frontend/            Kanban web (React)
frontend-dashboard/  Dashboard web (React)
frontend_mobile/     App para celular (Flutter)
```

---

## Como executar

**Pré-requisitos:** Docker Desktop com Kubernetes habilitado no modo **kubeadm** (*Settings → Kubernetes*), Flutter e Node.js.

**1. Gerar as imagens Docker** (a partir da pasta `backend`):

```powershell
cd backend\Barramento;         docker build -t barramento .
cd ..\Criar_Pedido;            docker build -t criar-pedido .
cd ..\Historico;               docker build -t historico .
cd ..\Dashboard;               docker build -t dashboard .
cd ..\configurar_produto_dart; docker build -t configurar-produto-dart:latest .
cd ..\MySQL;                   docker build -t mysql-velato .
```

**2. Implantar no Kubernetes** (os bancos são criados automaticamente):

```powershell
kubectl apply -f backend\Kubernetes\
kubectl get pods        # aguardar todos ficarem "Running"
```

**3. Acessar.** Os serviços ficam disponíveis direto no computador, em portas fixas:

| Serviço | Endereço |
|---|---|
| Criar_Pedido | http://localhost:30000 |
| Configurar_Produto | http://localhost:30001 |
| Dashboard | http://localhost:30004 |
| Historico | http://localhost:30005 |

**4. Abrir as telas** (cada uma em um terminal):

```powershell
cd frontend_mobile;    flutter pub get; flutter run -d chrome   # app para celular
cd frontend;           npm install;     npm run dev             # Kanban web    → http://localhost:5173
cd frontend-dashboard; npm install;     npm run dev             # Dashboard web → http://localhost:5174
```
