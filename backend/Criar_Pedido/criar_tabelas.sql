CREATE DATABASE KanBan;
USE KanBan;

-- Tabela Antiga (Mantida como histórico/backup temporário)
CREATE TABLE tarefas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    responsavel VARCHAR(100), 
    status VARCHAR(50) DEFAULT 'Pedidos'
);

-- 1. Criamos a tabela de catálogo (O que a Velato vende)
CREATE TABLE produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL
);

-- 2. Inserimos o catálogo inicial da Velato
INSERT INTO produtos (nome, preco) VALUES 
('Calça Alfaiataria Zíper Oculto', 259.90),
('Calça Cargo Utilitária', 289.00),
('Calça Jeans Slim Antifurto', 219.00);

-- 3. Criamos a tabela de pedidos (O "cabeçalho" do pedido no Kanban)
CREATE TABLE pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    responsavel VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Pedidos',
    prioridade INT DEFAULT 3,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. A tabela de ligação (Quais produtos estão em cada pedido)
CREATE TABLE itens_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT,
    produto_id INT,
    quantidade INT DEFAULT 1,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
);