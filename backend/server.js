const express = require('express')
const cors = require('cors')
const dotenv = require('dotenv').config()
const app = express()
const mysql = require('mysql2/promise')
app.use(cors())
app.use(express.json())

let conexao

async function conectar(){
    conexao = await mysql.createConnection({
        host: process.env.HOST,
        user: process.env.USERNAME,
        password: process.env.PASSWORD,
        database: process.env.DATABASE
    })
    console.log('Conectado ao MySQL!')
}

conectar()

app.get('/', (req, res) => {
    res.json({
        mensagem: 'Servidor funcionando'
    })
})

app.get('/tarefas', async (req, res) => {
    try{
        const [linhas] = await conexao.query('SELECT * FROM tarefas')
        res.json(linhas)
    } catch(erro){
        res.status(500).json({
            erro: 'Erro ao buscar tarefas.'
        })
    }
})

app.post('/tarefas', async (req, res) {
    try{
        const {titulo, descricao } = req.body
        const sql = 
            'INSERT INTO tarefas'
            + ' (titulo, descricao)'
            + ' VALUES (?, ?)'
        const [resultado] = 
            await conexao.query(sql, [titulo, descricao])
        res.status(201).json({
            id: resultado.insertId,
            titulo,
            descricao
        })
    } catch(erro){
        res.status(500).json({
            erro: 'Erro ao criar tarefa.'
        })
    }
})

app.listen(3000, () => {
    console.log('Servidor rodando na porta 3000.')
})