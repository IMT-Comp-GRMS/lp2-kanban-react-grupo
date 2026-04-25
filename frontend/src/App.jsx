import React from 'react';

const App = () => {

  // container padrão
  const containerStyle = {
    backgroundColor: '#F3F4F7',
    padding: '20px',
    fontFamily: 'sans-serif',
    minHeight: '100vh'
  };

  //botão criar pedido
  const botãoCriarPedido = {
    display: 'flex',
    alignItems: 'center',
    padding: '8px 16px',
    backgroundColor: '#D1D1D1',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    fontWeight: 'bold',
    marginBottom: '20px'
  };

  const kanbanContainerStyle = {
    display: 'flex',
    gap: '15px',
    justifyContent: 'space-between'
  };

  const colunaStyle = {
    backgroundColor: '#D9D9D9',
    width: '180px',
    minHeight: '400px',
    borderRadius: '8px',
    overflow: 'hidden'
  };

  const headerColunaStyle = {
    padding: '8px',
    textAlign: 'center',
    fontSize: '13px',
    fontWeight: '500'
  };

  // Dados das colunas para facilitar a renderização
  const colunas = [
    { titulo: 'Pedidos', cor: '#63E6BE' },
    { titulo: 'Pagamento Confirmado', cor: '#FFD43B' },
    { titulo: 'Pedido separado', cor: '#FF69B4' },
    { titulo: 'Pedido Enviado', cor: '#38B6FF' },
    { titulo: 'Pedido Entregue', cor: '#7ED957' },
  ];

  const [pedido, setpedido] = useState([]);

  const handleCriarPedido = async () => {
    const novoPedido = {
        titulo: "Novo Pedido de Teste",
        descricao: "Criado pelo botão do React",
        responsavel: "Rafaella" // O campo que adicionamos no MySQL!
    };

    try {
        const response = await fetch('http://localhost:3000/tarefas', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(novoPedido)
        });

        if (response.ok) {
            alert("Pedido criado no banco!");
            // Aqui você chamaria um GET para atualizar a tela
        }
    } catch (error) {
        console.error("Erro ao conectar:", error);
    }
 }

 return (
    <div style={containerStyle}>
      {/* Botão Superior */}
      <button style={botãoCriarPedido} 
      //torna o botão funcional
      onClick={handleCriarPedido} >
        <span style={{ color: 'darkblue', fontSize: '20px', marginRight: '8px' }}>+</span>
        Criar Pedido
      </button>

      {/* Container das Colunas */}
      <div style={kanbanContainerStyle}>
        {colunas.map((col, index) => (
          <div key={index} style={colunaStyle}>
            <div style={{ ...headerColunaStyle, backgroundColor: col.cor }}>
              {col.titulo}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

};

export default App;