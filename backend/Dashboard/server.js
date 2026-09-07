/**
 * ============================================================================
 * MICROSSERVIÇO DASHBOARD — Velato
 * Porta: 4000
 * ============================================================================
 * Responsabilidades:
 *   1. Expor os endpoints de leitura consumidos pelo frontend Dashboard.
 *   2. Receber eventos do Barramento (POST /eventos) e manter o banco
 *      BD_DashBoard atualizado como um Read Model.
 *
 * Banco de dados: BD_DashBoard (exclusivo deste microsserviço)
 * Barramento:     http://barramento-service:10000
 * ============================================================================
 */

require('dotenv').config();
const express = require('express');
const mysql   = require('mysql2/promise');
const cors    = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Variável global para manter a conexão viva com o banco de dados
let conexao;

/**
 * ============================================================================
 * CONEXÃO COM O BANCO DE DADOS
 * ============================================================================
 * Credenciais lidas do arquivo .env:
 *   HOST, USERBD, PASSWORD, DATABASE (deve apontar para BD_DashBoard)
 */
async function conectar() {
    try {
        conexao = await mysql.createConnection({
            host:     process.env.HOST,
            user:     process.env.USERBD,
            password: process.env.PASSWORD,
            database: process.env.DATABASE,
            charset:  'utf8mb4',
        });
        console.log('✅ Dashboard conectado ao MySQL (BD_DashBoard).');
    } catch (erro) {
        console.error('❌ Erro fatal ao conectar ao MySQL:', erro);
        process.exit(1); // sem banco o serviço não tem função
    }
}
conectar();

// ============================================================================
// ROTA DE SAÚDE
// GET /
// ============================================================================
app.get('/', (_req, res) => {
    res.json({ mensagem: 'Microsserviço Dashboard operando normalmente.' });
});

// ============================================================================
// ENDPOINT: KPIs PRINCIPAIS
// GET /dashboard/kpis
// ============================================================================
app.get('/dashboard/kpis', async (req, res) => {
    try {
        const sql = `
            SELECT
                (SELECT COUNT(*)
                 FROM pedidos)                                           AS totalPedidos,

                (SELECT COUNT(*)
                 FROM pedidos
                 WHERE status = 'Pedido Entregue'
                   AND DATE(data_entrega) = CURDATE())                  AS entreguesHoje,

                (SELECT COUNT(*)
                 FROM pedidos
                 WHERE prioridade = 1
                   AND status != 'Pedido Entregue')                            AS urgentesAberto,

                (SELECT COUNT(*)
                 FROM produtos)                                         AS totalProdutos
        `;

        const [[kpis]] = await conexao.query(sql);

        res.json({
            totalPedidos:   Number(kpis.totalPedidos),
            entreguesHoje:  Number(kpis.entreguesHoje),
            urgentesAberto: Number(kpis.urgentesAberto),
            totalProdutos:  Number(kpis.totalProdutos),
        });

    } catch (erro) {
        console.error('Erro no GET /dashboard/kpis:', erro);
        res.status(500).json({ erro: 'Erro ao calcular os KPIs do dashboard.' });
    }
});

// ============================================================================
// ENDPOINT: VOLUME DIÁRIO DE PEDIDOS
// GET /dashboard/volume-diario
// ============================================================================
app.get('/dashboard/volume-diario', async (_req, res) => {
    try {
        const sql = `
        SELECT
            DATE_FORMAT(MIN(data_criacao), '%d/%m') AS data,
            COUNT(*)                                AS pedidos
        FROM pedidos
        WHERE data_criacao >= CURDATE() - INTERVAL 6 DAY
        GROUP BY DATE(data_criacao)
        ORDER BY DATE(data_criacao) ASC
    `;
        const [linhas] = await conexao.query(sql);

        const mapa = {};
        linhas.forEach(({ data, pedidos }) => {
            mapa[data] = Number(pedidos);
        });

        const resultado = [];
        for (let diasAtras = 6; diasAtras >= 0; diasAtras--) {
            const d = new Date();
            d.setDate(d.getDate() - diasAtras);
            const chave = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
            resultado.push({ data: chave, pedidos: mapa[chave] ?? 0 });
        }

        res.json(resultado);

    } catch (erro) {
        console.error('Erro no GET /dashboard/volume-diario:', erro);
        res.status(500).json({ erro: 'Erro ao buscar volume diário de pedidos.' });
    }
});

// ============================================================================
// ENDPOINT: PRODUTOS MAIS PEDIDOS
// GET /dashboard/produtos-mais-pedidos
// ============================================================================
app.get('/dashboard/produtos-mais-pedidos', async (_req, res) => {
    try {
        const sql = `
            SELECT
                p.nome,
                SUM(ip.quantidade) AS pedidos
            FROM itens_pedido ip
            JOIN produtos p ON p.id = ip.produto_id
            GROUP BY p.id, p.nome
            ORDER BY pedidos DESC
            LIMIT 5
        `;
        const [linhas] = await conexao.query(sql);

        const resultado = linhas.map(({ nome, pedidos }) => ({
            nome,
            pedidos: Number(pedidos),
        }));

        res.json(resultado);

    } catch (erro) {
        console.error('Erro no GET /dashboard/produtos-mais-pedidos:', erro);
        res.status(500).json({ erro: 'Erro ao buscar produtos mais pedidos.' });
    }
});

// ============================================================================
// RECEPTOR DE EVENTOS DO BARRAMENTO
// POST /eventos
// ============================================================================
app.post('/eventos', async (req, res) => {
    // Responde imediatamente para não bloquear o Barramento
    res.status(200).json({ msg: 'ok' });

    const { tipo, dados } = req.body;

    try {
        // ------------------------------------------------------------------
        // ProdutoCriado — espelha o catálogo de produtos
        // ------------------------------------------------------------------
        if (tipo === 'ProdutoCriado') {
            const sql = `
                INSERT INTO produtos (id, nome, preco)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE nome = VALUES(nome), preco = VALUES(preco)
            `;
            await conexao.query(sql, [dados.id, dados.nome, dados.preco]);
            console.log(`📦 Produto espelhado: "${dados.nome}" (id ${dados.id})`);
        }

        // ------------------------------------------------------------------
        // PedidoCriado — registra o pedido e seus itens
        // ------------------------------------------------------------------
        else if (tipo === 'PedidoCriado') {
            const sqlPedido = `
                INSERT INTO pedidos (id, responsavel, status, prioridade, data_criacao)
                VALUES (?, ?, ?, ?, NOW())
                ON DUPLICATE KEY UPDATE status = VALUES(status)
            `;
            await conexao.query(sqlPedido, [
                dados.id,
                dados.responsavel ?? null,
                dados.status     ?? 'Pedidos',
                dados.prioridade ?? 3,
            ]);

            if (Array.isArray(dados.produtosIds) && dados.produtosIds.length > 0) {
                const itens = dados.produtosIds.map(produtoId => [dados.id, produtoId, 1]);
                await conexao.query(
                    'INSERT IGNORE INTO itens_pedido (pedido_id, produto_id, quantidade) VALUES ?',
                    [itens]
                );
            }

            console.log(`🧾 Pedido registrado no dashboard: id ${dados.id}`);
        }

        // ------------------------------------------------------------------
        // PedidoMovido — atualiza status; registra data de entrega se aplicável
        // ------------------------------------------------------------------
        else if (tipo === 'PedidoMovido') {
            const entregue = dados.status_novo === 'Pedido Entregue';

            const sql = entregue
                ? 'UPDATE pedidos SET status = ?, data_entrega = NOW() WHERE id = ?'
                : 'UPDATE pedidos SET status = ?                       WHERE id = ?';

            await conexao.query(sql, [dados.status_novo, dados.pedido_id]);
            console.log(`🔄 Pedido ${dados.pedido_id}: "${dados.status_anterior}" → "${dados.status_novo}"`);
        }

        else if (tipo === 'PedidoDeletado') {
            await conexao.query('DELETE FROM pedidos WHERE id = ?', [dados.pedido_id]);
            console.log(`🗑️ Pedido ${dados.pedido_id} removido do dashboard.`);
        }


    } catch (erro) {
        console.error(`❌ Erro ao processar evento "${tipo}":`, erro);
    }
});

// ============================================================================
// INICIALIZAÇÃO DO SERVIDOR
// ============================================================================
const PORTA = process.env.PORT || 4000;
app.listen(PORTA, () => {
    console.log(`🚀 Dashboard rodando na porta ${PORTA}`);
});