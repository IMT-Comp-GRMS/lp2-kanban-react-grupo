/**
 * ============================================================================
 * BACKEND VELATO - SISTEMA DE GESTÃO DE PEDIDOS (ERP/KANBAN)
 * ============================================================================
 * Este arquivo é o coração do servidor Node.js. Ele gerencia a comunicação
 * com o banco de dados MySQL estruturado de forma relacional (pedidos, 
 * produtos e itens_pedido).
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv').config();
const mysql = require('mysql2/promise');
const axios = require('axios');

const app = express();

// Middlewares: Permitem que o servidor entenda JSON e receba requisições do React
app.use(cors());
app.use(express.json());

// Variável global para manter a conexão viva com o banco de dados
let conexao;

/**
 * ============================================================================
 * CONEXÃO COM O BANCO DE DADOS
 * ============================================================================
 * Estabelece a conexão com o MySQL usando as credenciais do arquivo .env
 * (localmente) ou das variáveis de ambiente injetadas pelo Kubernetes
 * via ConfigMap/Secret (em produção/cluster).
 */
async function conectar() {
    try {
        conexao = await mysql.createConnection({
            host: process.env.HOST,
            user: process.env.USERBD,
            password: process.env.PASSWORD,
            database: process.env.DATABASE
        });
        console.log('✅ Conectado ao MySQL com sucesso!');
    } catch (erro) {
        console.error('❌ Erro fatal ao conectar ao MySQL:', erro);
    }
}
conectar();

/**
 * ============================================================================
 * ROTA DE SAÚDE (HEALTH CHECK)
 * Rota: GET /
 * ============================================================================
 * Verifica se o servidor está no ar.
 */
app.get('/', (req, res) => {
    res.json({ mensagem: 'Servidor da Velato operando normalmente.' });
});

/**
 * ============================================================================
 * ROTA: LISTAR CATÁLOGO DE PRODUTOS
 * Rota: GET /produtos
 * ============================================================================
 * Busca todos os produtos (calças) cadastrados no banco para alimentar
 * o formulário de "Novo Pedido" no Frontend.
 */
app.get('/produtos', async (req, res) => {
    try {
        const [produtos] = await conexao.query('SELECT * FROM produtos');
        res.json(produtos);
    } catch (erro) {
        console.error("Erro no /produtos:", erro);
        res.status(500).json({ erro: 'Erro ao buscar catálogo de produtos.' });
    }
});

/**
 * ============================================================================
 * ROTA: LER TODOS OS PEDIDOS (COM JOIN)
 * Rota: GET /tarefas
 * ============================================================================
 * Une as tabelas 'pedidos', 'itens_pedido' e 'produtos'.
 * O GROUP_CONCAT agrupa os nomes das calças em uma única string (ex: "Calça Cargo + Calça Slim")
 * e chamamos isso de 'titulo' para não quebrar a interface do Frontend atual.
 */
app.get('/tarefas', async (req, res) => {
    try {
        const sql = `
            SELECT 
                p.id, 
                p.responsavel, 
                p.descricao,
                p.status, 
                p.prioridade,
                IFNULL(GROUP_CONCAT(prod.nome SEPARATOR ' + '), 'Pedido Vazio') AS titulo
            FROM pedidos p
            LEFT JOIN itens_pedido ip ON p.id = ip.pedido_id
            LEFT JOIN produtos prod ON ip.produto_id = prod.id
            GROUP BY p.id
            ORDER BY p.prioridade ASC, p.id DESC
        `;
        const [linhas] = await conexao.query(sql);
        res.json(linhas);
    } catch (erro) {
        console.error("Erro no GET /tarefas:", erro);
        res.status(500).json({ erro: 'Erro ao buscar a lista de pedidos estruturados.' });
    }
});

/**
 * ============================================================================
 * ROTA: CRIAR NOVO PEDIDO E SEUS ITENS (TRANSAÇÃO)
 * Rota: POST /tarefas
 * ============================================================================
 * Recebe os dados gerais do pedido e um array numérico 'produtosIds' (ex: [1, 2]).
 * Salva o cabeçalho na tabela 'pedidos' e os vínculos na 'itens_pedido'.
 */
app.post('/tarefas', async (req, res) => {
    try {
        const { descricao, responsavel, prioridade, produtosIds } = req.body;
        const statusInicial = 'Pedidos'; 

        // 1. Inserimos apenas as informações de cabeçalho na nova tabela 'pedidos'
        const sqlPedido = 'INSERT INTO pedidos (responsavel, descricao, status, prioridade) VALUES (?, ?, ?, ?)';
        const [resultadoPedido] = await conexao.query(sqlPedido, [responsavel, descricao, statusInicial, prioridade]);
        
        const novoPedidoId = resultadoPedido.insertId;

        // 2. Se o React enviar um array de IDs de produtos, vinculamos eles ao pedido recém-criado
        if (produtosIds && produtosIds.length > 0) {
            // Transforma o array [1, 2] em [[novoPedidoId, 1], [novoPedidoId, 2]]
            const itensParaInserir = produtosIds.map(produtoId => [novoPedidoId, produtoId]);
            const sqlItens = 'INSERT INTO itens_pedido (pedido_id, produto_id) VALUES ?';
            
            await conexao.query(sqlItens, [itensParaInserir]);
        }

        // 3. Publica o evento no barramento para o dashboard
        await axios.post('http://barramento-service:10000/eventos', {
            tipo: 'PedidoCriado',
            dados: {
                id: novoPedidoId,
                responsavel,
                status: statusInicial,
                prioridade,
                produtosIds: produtosIds ?? []
            }
        }).catch(err => console.log('Barramento fora do ar:', err.message));
            
        res.status(201).json({ 
            mensagem: 'Pedido e itens criados com sucesso!', 
            id: novoPedidoId 
        });
    } catch (erro) {
        console.error("Erro no POST /tarefas:", erro);
        res.status(500).json({ erro: 'Erro ao criar o pedido e seus itens.' });
    }
});

/**
 * ============================================================================
 * ROTA: ATUALIZAR STATUS DO PEDIDO (MOVER NO KANBAN)
 * Rota: PUT /tarefas/:id
 * ============================================================================
 * Atualiza APENAS a coluna 'status' da tabela 'pedidos' (a tabela nova).
 */
app.put('/tarefas/:id', async (req, res) => {
    const idDoPedido = req.params.id;
    const { status, status_anterior } = req.body;

    try {
        const sql = 'UPDATE pedidos SET status = ? WHERE id = ?';
        const [resultado] = await conexao.execute(sql, [status, idDoPedido]);

        if (resultado.affectedRows === 0) {
            return res.status(404).json({ erro: 'Pedido não encontrado no banco de dados.' });
        }

        // Publica o evento no barramento para registrar no histórico e atualizar o dashboard
        await axios.post('http://barramento-service:10000/eventos', {
            tipo: 'PedidoMovido',
            dados: {
                pedido_id: idDoPedido,
                status_anterior: status_anterior,
                status_novo: status
            }
        }).catch(err => console.log('Barramento fora do ar:', err.message));

        res.status(200).json({ mensagem: 'Status do pedido atualizado com sucesso!' });
    } catch (erro) {
        console.error("Erro no PUT /tarefas:", erro);
        res.status(500).json({ erro: 'Erro interno ao tentar atualizar status.' });
    }
});

/**
 * ============================================================================
 * ROTA: DELETAR PEDIDO
 * Rota: DELETE /tarefas/:id
 * ============================================================================
 * Exclui o cabeçalho do pedido. Devido ao "ON DELETE CASCADE" configurado 
 * no banco, os itens vinculados na tabela itens_pedido sumirão automaticamente.
 */
app.delete('/tarefas/:id', async (req, res) => {
    const idDoPedido = req.params.id;

    try {
        const sql = 'DELETE FROM pedidos WHERE id = ?';
        const [resultado] = await conexao.query(sql, [idDoPedido]);

        if (resultado.affectedRows === 0) {
            return res.status(404).json({ erro: 'Pedido não encontrado para exclusão.' });
        }

        await axios.post('http://barramento-service:10000/eventos', {
            tipo: 'PedidoDeletado',
            dados: { pedido_id: idDoPedido }
        }).catch(err => console.log('Barramento fora do ar:', err.message));


        res.status(200).json({ mensagem: 'Pedido excluído com sucesso do sistema!' });
    } catch (erro) {
        console.error("Erro no DELETE /tarefas:", erro);
        res.status(500).json({ erro: 'Erro ao excluir o pedido.' });
    }
});

/**
 * ============================================================================
 * ROTA: OUVIR EVENTOS DO BARRAMENTO
 * Rota: POST /eventos
 * ============================================================================
 */
app.post('/eventos', async (req, res) => {
    const { tipo, dados } = req.body;

    if (tipo === 'ProdutoCriado') {
        try {
             const sql = `
            INSERT INTO produtos (id, nome, preco)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE nome = VALUES(nome), preco = VALUES(preco)
        `;
            await conexao.query(sql, [dados.id, dados.nome, dados.preco]);
            console.log(`✅ Produto "${dados.nome}" espelhado no banco principal.`);
        } catch (erro) {
            console.error('Erro ao espelhar produto:', erro);
        }
    }

    res.status(200).send({ msg: 'ok' });
});

/**
 * ============================================================================
 * ROTA: SINCRONIZAÇÃO COM O DASHBOARD
 * Rota: POST /sincronizar
 * ============================================================================
 * Republica todos os pedidos e produtos existentes no barramento para que
 * o dashboard seja populado com os dados históricos.
 */
app.post('/sincronizar', async (req, res) => {
    try {
        // 1. Republica todos os produtos
        const [produtos] = await conexao.query('SELECT * FROM produtos');
        for (const produto of produtos) {
            await axios.post('http://barramento-service:10000/eventos', {
                tipo: 'ProdutoCriado',
                dados: produto
            }).catch(err => console.log('Erro ao publicar produto:', err.message));
        }

        // 2. Republica todos os pedidos com seus itens
        const [pedidos] = await conexao.query('SELECT * FROM pedidos');
        for (const pedido of pedidos) {
            const [itens] = await conexao.query(
                'SELECT produto_id FROM itens_pedido WHERE pedido_id = ?',
                [pedido.id]
            );
            await axios.post('http://barramento-service:10000/eventos', {
                tipo: 'PedidoCriado',
                dados: {
                    id: pedido.id,
                    responsavel: pedido.responsavel,
                    status: pedido.status,
                    prioridade: pedido.prioridade,
                    produtosIds: itens.map(i => i.produto_id)
                }
            }).catch(err => console.log('Erro ao publicar pedido:', err.message));
        }

        res.status(200).json({ mensagem: `Sincronizados ${produtos.length} produtos e ${pedidos.length} pedidos.` });
    } catch (erro) {
        console.error('Erro na sincronização:', erro);
        res.status(500).json({ erro: 'Erro ao sincronizar.' });
    }
});

app.listen(3000, () => {
    console.log('Criar_Pedido. Porta 3000')
})