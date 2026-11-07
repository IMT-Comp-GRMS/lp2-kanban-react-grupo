-- ============================================================
-- BD_Produtos (Configurar_Produto)
-- ============================================================
CREATE DATABASE IF NOT EXISTS BD_Produtos;
USE BD_Produtos;

CREATE TABLE IF NOT EXISTS produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL
);

-- ============================================================
-- KanBan (Criar_Pedido)
-- ============================================================
CREATE DATABASE IF NOT EXISTS KanBan;
USE KanBan;

CREATE TABLE IF NOT EXISTS tarefas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    responsavel VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Pedidos'
);

CREATE TABLE IF NOT EXISTS produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL
);

INSERT INTO produtos (nome, preco) VALUES
('Calça Alfaiataria Zíper Oculto', 259.90),
('Calça Cargo Utilitária', 289.00),
('Calça Jeans Slim Antifurto', 219.00);

CREATE TABLE IF NOT EXISTS pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    responsavel VARCHAR(100),
    descricao VARCHAR(255),
    status VARCHAR(50) DEFAULT 'Pedidos',
    prioridade INT DEFAULT 3,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS itens_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT,
    produto_id INT,
    quantidade INT DEFAULT 1,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

-- ============================================================
-- BD_Historico (Historico)
-- ============================================================
CREATE DATABASE IF NOT EXISTS BD_Historico;
USE BD_Historico;

CREATE TABLE IF NOT EXISTS historico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    status_anterior VARCHAR(50),
    status_novo VARCHAR(50) NOT NULL,
    data_hora DATETIME DEFAULT NOW()
);

-- ============================================================
-- BD_DashBoard (Dashboard)
-- ============================================================
CREATE DATABASE IF NOT EXISTS BD_DashBoard
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE BD_DashBoard;

CREATE TABLE IF NOT EXISTS produtos (
    id            INT            NOT NULL,
    nome          VARCHAR(100)   NOT NULL,
    preco         DECIMAL(10,2)  NOT NULL,
    atualizado_em TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS pedidos (
    id            INT            NOT NULL,
    responsavel   VARCHAR(100),
    status        VARCHAR(50)    NOT NULL DEFAULT 'Pedidos',
    prioridade    INT            NOT NULL DEFAULT 3,
    data_criacao  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_entrega  TIMESTAMP      NULL DEFAULT NULL,
    atualizado_em TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_status_entrega  (status, data_entrega),
    INDEX idx_data_criacao    (data_criacao),
    INDEX idx_prioridade_status (prioridade, status)
);

CREATE TABLE IF NOT EXISTS itens_pedido (
    id          INT  NOT NULL AUTO_INCREMENT,
    pedido_id   INT  NOT NULL,
    produto_id  INT  NOT NULL,
    quantidade  INT  NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    FOREIGN KEY (pedido_id)  REFERENCES pedidos(id)  ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE,
    INDEX idx_produto_id (produto_id)
);
