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

/* ==========================================================================
   2. ROTAS
   ========================================================================== */

/**
 * GET /produtos
 * Retorna todos os produtos cadastrados no banco.
 */
app.get('/produtos', async (req, res) => {
  try {
    const [resultados] = await conexao.query('SELECT * FROM produtos');
    res.json(resultados);
  } catch (erro) {
    console.error('Erro ao buscar produtos:', erro);
    res.status(500).json({ mensagem: 'Erro interno do servidor.' });
  }
});

/**
 * POST /produtos
 * Recebe { nome, preco } e insere um novo produto no banco.
 */
app.post('/produtos', async (req, res) => {
  const { nome, preco } = req.body;

  if (!nome || !preco) {
    return res.status(400).json({ mensagem: 'Nome e preço são obrigatórios.' });
  }

  try {
    const sql = 'INSERT INTO produtos (nome, preco) VALUES (?, ?)';
    const [resultado] = await conexao.query(sql, [nome, preco]);

    const produtoCriado = { id: resultado.insertId, nome, preco };

    //nome do Service do barramento no Kubernetes, em vez de localhost
    await axios.post('http://barramento-service:10000/eventos', {
      tipo: 'ProdutoCriado',
      dados: produtoCriado
    }).catch(err => console.log('Barramento fora do ar:', err.message));

    res.status(201).json(produtoCriado);
  } catch (erro) {
    console.error('Erro ao inserir produto:', erro);
    res.status(500).json({ mensagem: 'Erro interno do servidor.' });
  }
});

/* ==========================================================================
   3. INICIALIZAÇÃO DO SERVIDOR
   ========================================================================== */
app.listen(3001, () => {
    console.log('Configurar_Produto. Porta 3001')
})