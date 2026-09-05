const express = require('express')
const axios = require('axios')
const app = express()
app.use(express.json())

app.post('/eventos', (req, res) => {
    const evento = req.body

    //Criar_Produto só emite eventos, nunca recebe - não é destino aqui

    //envia o evento para o microsserviço de Criar_Pedido (emite e recebe)
    axios.post('http://criar-pedido-service:3000/eventos', evento)
    .catch((err) => {
        console.log('Microsserviço de Criar_Pedido fora do ar.')
    })

    //envia o evento para o microsserviço de Historico (só recebe)
    axios.post('http://historico-service:5001/eventos', evento)
    .catch((err) => {
        console.log('Microsserviço de Histórico fora do ar.')
    })

    res.status(200).send({msg: 'ok'})

    //envia o evento para o microsserviço de Dashboard (só recebe)
    axios.post('http://dashboard-service:4000/eventos', evento)
    .catch((err) => {
        console.log('Microsserviço Dashboard fora do ar.')
    })
})

app.listen(10000, () => {
    console.log('Barramento de eventos. Porta 10000.')
})