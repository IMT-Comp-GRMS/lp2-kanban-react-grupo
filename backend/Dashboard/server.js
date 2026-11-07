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
const axios   = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

// Pool de conexões com o banco de dados (criado em conectar())
let conexao;

/**
 * ============================================================================
 * CONEXÃO COM O BANCO DE DADOS
 * ============================================================================
 * Credenciais lidas do arquivo .env:
 *   HOST, USERBD, PASSWORD, DATABASE (deve apontar para BD_DashBoard)
 */
async function conectar() {
    // Pool de conexões (mesmo conceito do MySQLConnectionPool do serviço Dart):
    // em vez de UMA conexão aberta só na partida, o pool abre conexões quando
    // precisa e as reaproveita. Se o MySQL ainda não estiver pronto (ou reiniciar),
    // a próxima consulta abre uma conexão nova e o serviço se recupera sozinho.
    conexao = mysql.createPool({
        host:     process.env.HOST,
        user:     process.env.USERBD,
        password: process.env.PASSWORD,
        database: process.env.DATABASE,
        charset:  'utf8mb4',
        // Mesmo fuso do MySQL (--default-time-zone=-03:00) para as datas que
        // chegam nos eventos (data_criacao, data_movimentacao).
        timezone: '-03:00',
        connectionLimit: 10,
    });
    try {
        await conexao.query('SELECT 1');
        console.log('✅ Dashboard conectado ao MySQL (BD_DashBoard).');
    } catch (erro) {
        console.error('⚠️ MySQL ainda indisponível; o pool tentará de novo na próxima requisição:', erro.message);
    }
}
// Guarda a Promise para a recuperação de eventos esperar o banco.
const conectado = conectar();

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
// MAPA DE FUNÇÕES POR TIPO DE EVENTO
// ============================================================================
// Padrão da apostila Microsserviços 4.3.37 e 4.3.47: cada tipo de evento é uma
// chave do objeto `funcoes`. Cada função tem seu próprio try/catch para que
// erros de banco apareçam no log (o catch da rota é vazio de propósito).
const funcoes = {
    // ProdutoCriado — espelha o catálogo de produtos
    ProdutoCriado: async (dados) => {
        try {
            const sql = `
                INSERT INTO produtos (id, nome, preco)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE nome = VALUES(nome), preco = VALUES(preco)
            `;
            await conexao.query(sql, [dados.id, dados.nome, dados.preco]);
            console.log(`📦 Produto espelhado: "${dados.nome}" (id ${dados.id})`);
        } catch (erro) {
            console.error('❌ Erro ao processar evento "ProdutoCriado":', erro);
        }
    },

    // PedidoCriado — registra o pedido e seus itens
    PedidoCriado: async (dados) => {
        try {
            const sqlPedido = `
                INSERT INTO pedidos (id, responsavel, status, prioridade, data_criacao)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE status = VALUES(status)
            `;
            // Usa a data real do pedido (enviada pelo Criar_Pedido) e não a hora
            // em que o evento foi processado, para o gráfico de volume diário
            // ficar certo quando o evento é reprocessado depois.
            const dataCriacao = dados.data_criacao ? new Date(dados.data_criacao) : new Date();
            await conexao.query(sqlPedido, [
                dados.id,
                dados.responsavel ?? null,
                dados.status     ?? 'Pedidos',
                dados.prioridade ?? 3,
                dataCriacao,
            ]);

            if (Array.isArray(dados.produtosIds) && dados.produtosIds.length > 0) {
                const itens = dados.produtosIds.map(produtoId => [dados.id, produtoId, 1]);
                await conexao.query(
                    'INSERT IGNORE INTO itens_pedido (pedido_id, produto_id, quantidade) VALUES ?',
                    [itens]
                );
            }

            console.log(`🧾 Pedido registrado no dashboard: id ${dados.id}`);
        } catch (erro) {
            console.error('❌ Erro ao processar evento "PedidoCriado":', erro);
        }
    },

    // PedidoMovido — atualiza status; registra data de entrega se aplicável
    PedidoMovido: async (dados) => {
        try {
            const entregue = dados.status_novo === 'Pedido Entregue';

            // Data real da movimentação (enviada pelo Criar_Pedido); eventos
            // antigos, sem a data, usam a hora atual.
            const dataMov = dados.data_movimentacao ? new Date(dados.data_movimentacao) : new Date();

            if (entregue) {
                await conexao.query(
                    'UPDATE pedidos SET status = ?, data_entrega = ? WHERE id = ?',
                    [dados.status_novo, dataMov, dados.pedido_id]
                );
            } else {
                await conexao.query(
                    'UPDATE pedidos SET status = ? WHERE id = ?',
                    [dados.status_novo, dados.pedido_id]
                );
            }
            console.log(`🔄 Pedido ${dados.pedido_id}: "${dados.status_anterior}" → "${dados.status_novo}"`);
        } catch (erro) {
            console.error('❌ Erro ao processar evento "PedidoMovido":', erro);
        }
    },

    // PedidoDeletado — remove o pedido (os itens saem pelo ON DELETE CASCADE)
    PedidoDeletado: async (dados) => {
        try {
            await conexao.query('DELETE FROM pedidos WHERE id = ?', [dados.pedido_id]);
            console.log(`🗑️ Pedido ${dados.pedido_id} removido do dashboard.`);
        } catch (erro) {
            console.error('❌ Erro ao processar evento "PedidoDeletado":', erro);
        }
    }
};

// ============================================================================
// RECEPTOR DE EVENTOS DO BARRAMENTO
// POST /eventos
// ============================================================================
app.post('/eventos', async (req, res) => {
    // Responde imediatamente para não bloquear o Barramento
    res.status(200).json({ msg: 'ok' });

    const { tipo, dados } = req.body;

    // Apostila Microsserviços 4.3.47: o catch vazio ignora os eventos que
    // não estão no mapa (funcoes[tipo] é undefined e a chamada lança erro).
    try {
        await funcoes[tipo](dados);
    } catch (err) {}
});

// ============================================================================
// RECUPERAÇÃO DE EVENTOS PERDIDOS
// ============================================================================
// Apostila Microsserviços 4.3.51: ao subir, pede ao barramento os eventos
// guardados e processa cada um. As consultas usam ON DUPLICATE KEY / INSERT
// IGNORE pelo id do pedido ou produto, então reprocessar não duplica linhas.
async function recuperarEventos() {
    try {
        const resposta = await axios.get('http://barramento-service:10000/eventos');
        console.log(`🔁 Recuperando ${resposta.data.length} evento(s) do barramento...`);
        for (const evento of resposta.data) {
            try {
                await funcoes[evento.tipo](evento.dados);
            } catch (err) {}
        }
    } catch (erro) {
        // O barramento pode ainda não estar no ar quando este serviço sobe.
        console.error('⚠️ Não foi possível recuperar eventos do barramento:', erro.message);
    }
}

// ============================================================================
// INICIALIZAÇÃO DO SERVIDOR
// ============================================================================
const PORTA = process.env.PORT || 4000;
app.listen(PORTA, async () => {
    console.log(`🚀 Dashboard rodando na porta ${PORTA}`);
    await conectado;
    await recuperarEventos();
});