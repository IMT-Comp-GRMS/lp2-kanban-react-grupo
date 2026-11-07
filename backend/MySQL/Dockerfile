# Imagem do MySQL do Velato Flow
# Parte da imagem oficial e coloca o script de criação dos bancos na pasta
# /docker-entrypoint-initdb.d. Na PRIMEIRA vez que o contêiner sobe (pasta de
# dados vazia), o MySQL executa sozinho, em ordem alfabética, todo .sql dessa
# pasta: cria os 4 bancos e as tabelas sem nenhum passo manual.
FROM mysql:8
COPY 01-setup_bancos.sql /docker-entrypoint-initdb.d/
