const express = require('express')
const axios = require('axios')
const app = express()
app.use(express.json())

// Apostila Microsserviços 4.3.50: o barramento guarda todos os eventos que
// recebe, para que um serviço que estava fora do ar possa pedi-los depois.
// Como na apostila, os eventos ficam em memória: se o Pod do barramento
// reiniciar, o vetor volta vazio e os eventos antigos se perdem.
const eventos = []
let proximoId = 1

app.post('/eventos', (req, res) => {
    const evento = req.body

    // O id permite que os serviços não processem o mesmo evento duas vezes
    // quando recuperarem os eventos perdidos.
    evento.id = proximoId++
    eventos.push(evento)

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

// Apostila Microsserviços 4.3.50: devolve todos os eventos guardados.
app.get('/eventos', (req, res) => {
    res.send(eventos)
})

app.listen(10000, () => {
    console.log('Barramento de eventos. Porta 10000.')
})