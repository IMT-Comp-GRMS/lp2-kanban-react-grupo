-- ============================================================================
-- BD_DashBoard.sql
-- Banco de dados do microsserviço Dashboard — Velato
-- ============================================================================
-- ARQUITETURA:
--   Este banco é um READ MODEL (projeção de leitura).
--   Ele NÃO acessa diretamente o banco do Kanban.
--   Os dados chegam via BARRAMENTO DE EVENTOS e são persistidos aqui,
--   prontos para as queries de dashboard (baixa latência, sem JOINs externos).
--
-- ENDPOINTS QUE ESTE BANCO SUPORTA:
--   GET /dashboard/kpis
--   GET /dashboard/volume-diario
--   GET /dashboard/produtos-mais-pedidos
-- ============================================================================

CREATE DATABASE IF NOT EXISTS BD_DashBoard
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE BD_DashBoard;

-- ============================================================================
-- TABELA: produtos
-- Projeção do catálogo de produtos recebida do barramento.
-- Evento de origem: produto.criado | produto.atualizado | produto.removido
-- ============================================================================
CREATE TABLE produtos (
    id            INT            NOT NULL,          -- mesmo ID do serviço de origem
    nome          VARCHAR(100)   NOT NULL,
    preco         DECIMAL(10,2)  NOT NULL,
    atualizado_em TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id)
);

-- ============================================================================
-- TABELA: pedidos
-- Projeção dos pedidos recebida do barramento.
-- Evento de origem: pedido.criado | pedido.atualizado | pedido.entregue
--
-- Colunas-chave para os KPIs:
--   status        → filtra "Entregue" e statuses abertos
--   prioridade    → 1 = Urgente | 2 = Alta | 3 = Normal (padrão)
--   data_criacao  → usada no gráfico de volume diário
--   data_entrega  → preenchida quando status muda para 'Entregue';
--                   filtra o KPI "entreguesHoje"
-- ============================================================================
CREATE TABLE pedidos (
    id            INT            NOT NULL,          -- mesmo ID do serviço de origem
    responsavel   VARCHAR(100),
    status        VARCHAR(50)    NOT NULL DEFAULT 'Pedidos',
    prioridade    INT            NOT NULL DEFAULT 3,
    data_criacao  TIMESTAMP      NOT NULL,
    data_entrega  TIMESTAMP      NULL DEFAULT NULL, -- preenchido ao entregar
    atualizado_em TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    -- Índice para o KPI "entreguesHoje":
    --   WHERE status = 'Entregue' AND DATE(data_entrega) = CURDATE()
    INDEX idx_status_entrega  (status, data_entrega),

    -- Índice para o volume diário:
    --   WHERE data_criacao >= CURDATE() - INTERVAL 6 DAY
    INDEX idx_data_criacao    (data_criacao),

    -- Índice para o KPI "urgentesAberto":
    --   WHERE prioridade = 1 AND status != 'Entregue'
    INDEX idx_prioridade_status (prioridade, status)
);

-- ============================================================================
-- TABELA: itens_pedido
-- Relação entre pedidos e produtos (recebida do barramento junto com o pedido).
-- Evento de origem: pedido.criado
-- Usada para calcular o ranking "produtos mais pedidos".
-- ============================================================================
CREATE TABLE itens_pedido (
    id          INT  NOT NULL AUTO_INCREMENT,
    pedido_id   INT  NOT NULL,
    produto_id  INT  NOT NULL,
    quantidade  INT  NOT NULL DEFAULT 1,

    PRIMARY KEY (id),
    FOREIGN KEY (pedido_id)  REFERENCES pedidos(id)  ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE,

    -- Índice para o gráfico de produtos mais pedidos:
    --   GROUP BY produto_id
    INDEX idx_produto_id (produto_id)
);


-- ============================================================================
-- QUERIES DOS ENDPOINTS (documentação — executadas pelo backend Node.js)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- GET /dashboard/kpis
-- ----------------------------------------------------------------------------
/*
SELECT
    (SELECT COUNT(*)        FROM pedidos)                                               AS totalPedidos,
    (SELECT COUNT(*)        FROM pedidos
     WHERE status = 'Entregue'
       AND DATE(data_entrega) = CURDATE())                                              AS entreguesHoje,
    (SELECT COUNT(*)        FROM pedidos
     WHERE prioridade = 1
       AND status != 'Entregue')                                                        AS urgentesAberto,
    (SELECT COUNT(*)        FROM produtos)                                              AS totalProdutos;
*/

-- ----------------------------------------------------------------------------
-- GET /dashboard/volume-diario  (últimos 7 dias, incluindo hoje)
-- ----------------------------------------------------------------------------
/*
SELECT
    DATE_FORMAT(data_criacao, '%d/%m')  AS data,
    COUNT(*)                            AS pedidos
FROM pedidos
WHERE data_criacao >= CURDATE() - INTERVAL 6 DAY
GROUP BY DATE(data_criacao)
ORDER BY DATE(data_criacao) ASC;
*/

-- ----------------------------------------------------------------------------
-- GET /dashboard/produtos-mais-pedidos  (top 5)
-- ----------------------------------------------------------------------------
/*
SELECT
    p.nome,
    SUM(ip.quantidade)  AS pedidos
FROM itens_pedido ip
JOIN produtos p ON p.id = ip.produto_id
GROUP BY p.id, p.nome
ORDER BY pedidos DESC
LIMIT 5;
*/
