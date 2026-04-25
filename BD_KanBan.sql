CREATE DATABASE KanBan;
use KanBan;
CREATE TABLE tarefas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    responsavel VARCHAR(100), 
    status VARCHAR(50) DEFAULT 'Pedidos'
);

select * from tarefas

