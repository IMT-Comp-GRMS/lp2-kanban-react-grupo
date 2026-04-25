import React, { useState } from 'react';

const App = () => {
  // 1. Estilos
  const containerStyle = {
    backgroundColor: '#F3F4F7',
    padding: '20px',
    fontFamily: 'sans-serif',
    minHeight: '100vh'
  };

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

  const modalOverlayStyle = {
    position: 'fixed',
    top: 0,
    left: 0,
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000
  };

  const modalContentStyle = {
    backgroundColor: 'white',
    padding: '30px',
    borderRadius: '12px',
    width: '350px',
    display: 'flex',
    flexDirection: 'column',
    gap: '15px'
  };

  const inputStyle = {
    padding: '10px',
    borderRadius: '6px',
    border: '1px solid #ccc'
  };

  // 2. Dados e Estados
  const colunas = [
    { titulo: 'Pedidos', cor: '#63E6BE' },
    { titulo: 'Pagamento Confirmado', cor: '#FFD43B' },
    { titulo: 'Pedido separado', cor: '#FF69B4' },
    { titulo: 'Pedido Enviado', cor: '#38B6FF' },
    { titulo: 'Pedido Entregue', cor: '#7ED957' },
  ];



  const [pedidos, setPedidos] = useState([]);
  const [titulo, setTitulo] = useState('');
  const [descricao, setDescricao] = useState('');
  const [responsavel, setResponsavel] = useState('');
  const [mostrarModal, setMostrarModal] = useState(false); // Para abrir/fechar a janelinha

  // 3. Função do Botão
  const handleCriarPedido = async () => {
    const novoPedido = {
        titulo: titulo,         // Usa o que foi digitado
        descricao: descricao,   // Usa o que foi digitado
        responsavel: responsavel // Usa o que foi digitado
    };

    try {
        const response = await fetch('http://localhost:3000/tarefas', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(novoPedido)
        });

        if (response.ok) {
          alert("Pedido salvo com sucesso!");
            setMostrarModal(false); // Fecha o modal
            setTitulo(''); setDescricao(''); setResponsavel(''); // Limpa os campos
            // Chamar a função de carregar dados aqui (o item 2 que você mencionou)
        }
    } catch (error) {
        console.error("Erro ao conectar:", error);
        alert("Não foi possível conectar ao servidor. O Backend está rodando?");
    }
  };

 
  // 4. Renderização
  return (
    <div style={containerStyle}>
      {mostrarModal && (
        <div style={modalOverlayStyle}>
          <div style={modalContentStyle}>
            <h3>Novo Pedido</h3>
            <input 
              placeholder="Título do Pedido" 
              value={titulo} 
              onChange={(e) => setTitulo(e.target.value)} 
              style={inputStyle}
            />
            <textarea 
              placeholder="Descrição" 
              value={descricao} 
              onChange={(e) => setDescricao(e.target.value)} 
              style={inputStyle}
            />
            <input 
              placeholder="Responsável" 
              value={responsavel} 
              onChange={(e) => setResponsavel(e.target.value)} 
              style={inputStyle}
            />
            <button onClick={handleCriarPedido}>Salvar Pedido</button>
            <button onClick={() => setMostrarModal(false)}>Cancelar</button>
          </div>
        </div>
        )}

      <button style={botãoCriarPedido} onClick={() => setMostrarModal(true)}>
        <span style={{ color: 'darkblue', fontSize: '20px', marginRight: '8px' }}>+</span>
        Criar Pedido
      </button>

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