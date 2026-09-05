CREATE database BD_Historico;
USE BD_Historico;

CREATE TABLE historico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL, 
    status_anterior VARCHAR(50),
    status_novo VARCHAR(50) NOT NULL,
    data_hora DATETIME DEFAULT NOW ()
);                