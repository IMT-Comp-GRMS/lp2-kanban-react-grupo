require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const axios = require('axios');

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
    // Pool de conexões (mesmo conceito do MySQLConnectionPool do serviço Dart):
    // em vez de UMA conexão aberta só na partida, o pool abre conexões quando
    // precisa e as reaproveita. Se o MySQL ainda não estiver pronto (ou reiniciar),
    // a próxima consulta abre uma conexão nova e o serviço se recupera sozinho.
    conexao = mysql.createPool({
        host: process.env.HOST,
        user: process.env.USERBD,
        password: process.env.PASSWORD,
        database: process.env.DATABASE,
        charset: 'utf8mb4',
        connectionLimit: 10
    });
    try {
        await conexao.query('SELECT 1');
        console.log('✅ Conectado ao BD_Historico com sucesso!');
    } catch (erro) {
        console.error('⚠️ MySQL ainda indisponível; o pool tentará de novo na próxima requisição:', erro.message);
    }
}
// Guarda a Promise para a recuperação de eventos esperar o banco.
const conectado = conectar();

/**
 * ============================================================================
 * MAPA DE FUNÇÕES POR TIPO DE EVENTO
 * ============================================================================
 * Padrão da apostila Microsserviços 4.3.47: cada tipo de evento que interessa
 * a este serviço é uma chave do objeto `funcoes`, e o valor é a função que o
 * trata. Para tratar um evento novo, basta acrescentar uma chave.
 */
const funcoes = {
    // Registra a movimentação do pedido na tabela historico.
    // Apostila Microsserviços 4.3.51: o eventoId (id do evento no barramento)
    // vai para a coluna UNIQUE evento_id. Com INSERT IGNORE, um evento que já
    // foi gravado é ignorado, então reprocessar os eventos não duplica linhas.
    PedidoMovido: async (dados, eventoId) => {
        try {
            const sql = 'INSERT IGNORE INTO historico (evento_id, pedido_id, status_anterior, status_novo) VALUES (?, ?, ?, ?)';
            const [resultado] = await conexao.query(sql, [eventoId ?? null, dados.pedido_id, dados.status_anterior, dados.status_novo]);
            if (resultado.affectedRows === 0) {
                console.log(`↩️ Evento ${eventoId} já registrado; ignorado.`);
                return;
            }
            console.log(`✅ Histórico registrado: Pedido #${dados.pedido_id} movido de "${dados.status_anterior}" para "${dados.status_novo}"`);
        } catch (erro) {
            console.error('Erro ao registrar histórico:', erro);
        }
    }
};

/**
 * ============================================================================
 * ROTA: OUVIR EVENTOS DO BARRAMENTO
 * Rota: POST /eventos
 * ============================================================================
 * Recebe eventos do barramento e chama a função do mapa `funcoes`
 * correspondente ao tipo do evento.
 */
app.post('/eventos', async (req, res) => {
    const { tipo, dados, id } = req.body;

    // Como na apostila Microsserviços 4.3.47: se o tipo não estiver no mapa,
    // funcoes[tipo] é undefined e a chamada lança erro. O catch vazio ignora
    // de propósito os eventos que não interessam a este serviço.
    try {
        await funcoes[tipo](dados, id);
    } catch (err) {}

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
/**
 * ============================================================================
 * RECUPERAÇÃO DE EVENTOS PERDIDOS
 * ============================================================================
 * Apostila Microsserviços 4.3.51: ao subir, o serviço pede ao barramento todos
 * os eventos guardados e processa cada um. Assim, o que aconteceu enquanto o
 * Historico estava fora do ar entra no banco. O evento_id UNIQUE garante que
 * os eventos já gravados não sejam duplicados.
 */
async function recuperarEventos() {
    try {
        const resposta = await axios.get('http://barramento-service:10000/eventos');
        console.log(`🔁 Recuperando ${resposta.data.length} evento(s) do barramento...`);
        for (const evento of resposta.data) {
            // try/catch individual: um evento com problema (ou de um tipo que
            // não interessa) não impede o processamento dos próximos.
            try {
                await funcoes[evento.tipo](evento.dados, evento.id);
            } catch (err) {}
        }
    } catch (erro) {
        // No Kubernetes o barramento pode ainda não estar no ar quando o
        // Historico sobe; nesse caso o serviço segue normalmente.
        console.error('⚠️ Não foi possível recuperar eventos do barramento:', erro.message);
    }
}

app.listen(5001, async () => {
    console.log('Microsserviço de Histórico. Porta 5001.');
    // Espera a conexão com o banco ficar pronta antes de reprocessar.
    await conectado;
    await recuperarEventos();
});