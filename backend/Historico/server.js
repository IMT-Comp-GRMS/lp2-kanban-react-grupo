require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

let conexao;

/**
 * ============================================================================
 * CONEXÃO COM O BANCO DE DADOS
 * ============================================================================
 * Estabelece a conexão com o MySQL usando as credenciais do arquivo .env.
 */
async function conectar() {
    try {
        conexao = await mysql.createConnection({
            host: process.env.HOST,
            user: process.env.USERBD,
            password: process.env.PASSWORD,
            database: process.env.DATABASE,
            charset: 'utf8mb4'
        });
        console.log('✅ Conectado ao BD_Historico com sucesso!');
    } catch (erro) {
        console.error('❌ Erro fatal ao conectar ao MySQL:', erro);
    }
}
conectar();

/**
 * ============================================================================
 * ROTA: OUVIR EVENTOS DO BARRAMENTO
 * Rota: POST /eventos
 * ============================================================================
 * Recebe eventos do barramento. Quando o tipo for 'PedidoMovido',
 * registra a movimentação na tabela historico.
 */
app.post('/eventos', async (req, res) => {
    const { tipo, dados } = req.body;

    if (tipo === 'PedidoMovido') {
        try {
            const sql = 'INSERT INTO historico (pedido_id, status_anterior, status_novo) VALUES (?, ?, ?)';
            await conexao.query(sql, [dados.pedido_id, dados.status_anterior, dados.status_novo]);
            console.log(`✅ Histórico registrado: Pedido #${dados.pedido_id} movido de "${dados.status_anterior}" para "${dados.status_novo}"`);
        } catch (erro) {
            console.error('Erro ao registrar histórico:', erro);
        }
    }

    res.status(200).send({ msg: 'ok' });
});

/**
 * ============================================================================
 * ROTA: BUSCAR HISTÓRICO DE UM PEDIDO
 * Rota: GET /historico/:pedido_id
 * ============================================================================
 * Retorna todas as movimentações de um pedido específico,
 * ordenadas da mais recente para a mais antiga.
 */
app.get('/historico/:pedido_id', async (req, res) => {
    const { pedido_id } = req.params;

    try {
        const sql = `
            SELECT 
                id,
                pedido_id,
                status_anterior,
                status_novo,
                DATE_FORMAT(data_hora, '%d/%m/%Y %H:%i:%s') AS data_hora
            FROM historico
            WHERE pedido_id = ?
            ORDER BY data_hora DESC
        `;
        const [linhas] = await conexao.query(sql, [pedido_id]);

        if (linhas.length === 0) {
            return res.status(404).json({ mensagem: 'Nenhum histórico encontrado para este pedido.' });
        }

        res.json(linhas);
    } catch (erro) {
        console.error('Erro ao buscar histórico:', erro);
        res.status(500).json({ erro: 'Erro ao buscar histórico do pedido.' });
    }
});

/**
 * ============================================================================
 * INICIALIZAÇÃO DO SERVIDOR
 * ============================================================================
 */
app.listen(5001, () => {
    console.log('Microsserviço de Histórico. Porta 5001.');
});