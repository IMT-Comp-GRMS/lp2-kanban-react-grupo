import React, { useState, useEffect } from 'react';
import CardPedido from './CardPedido';
import { useSelector, useDispatch } from 'react-redux';
import { salvarPedidosNoCofre } from './store/pedidosSlice';

/* ==========================================================================
   URLS DA API — Kubernetes (NodePort)
   ========================================================================== */
const URL_CRIAR_PEDIDO = 'http://localhost:30991';       // era :3000
const URL_CONFIGURAR_PRODUTO = 'http://localhost:32358';  // era :3001

const App = () => {
  const dispatch = useDispatch();
  const pedidos = useSelector((state) => state.pedidos.lista);

  const [catalogo, setCatalogo] = useState([]);
  const [produtosSelecionados, setProdutosSelecionados] = useState([]);
  const [descricao, setDescricao] = useState('');
  const [responsavel, setResponsavel] = useState('');
  const [prioridade, setPrioridade] = useState(3);
  const [mostrarModal, setMostrarModal] = useState(false);
  const [termoBusca, setTermoBusca] = useState('');
  const [filtroPrioridade, setFiltroPrioridade] = useState('TODAS');
  const [mostrarModalProduto, setMostrarModalProduto] = useState(false);
  const [nomeProduto, setNomeProduto] = useState('');
  const [precoProduto, setPrecoProduto] = useState('');

  const containerStyle = {
    backgroundColor: '#f6f0e7',
    fontFamily: "'Inter', 'Helvetica Neue', Helvetica, Arial, sans-serif",
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    color: '#252623'
  };

  const headerVelatoStyle = {
    backgroundColor: '#f6f0e7',
    padding: '20px 40px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottom: '2px solid #3c5262',
    marginBottom: '30px'
  };

  const botãoCriarPedido = {
    padding: '10px 24px',
    backgroundColor: '#ae4f48',
    color: '#f6f0e7',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    fontWeight: '600',
    fontSize: '14px',
    transition: 'opacity 0.2s',
    display: 'flex',
    alignItems: 'center',
    gap: '8px'
  };

  const botãoConfigurarProduto = {
    padding: '10px 24px',
    backgroundColor: '#2e1172',
    color: '#f6f0e7',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    fontWeight: '600',
    fontSize: '14px',
    transition: 'opacity 0.2s',
    display: 'flex',
    alignItems: 'center',
    gap: '8px'
  };

  const kanbanContainerStyle = {
    display: 'flex',
    gap: '24px',
    width: '100%',
    padding: '0 40px 40px 40px',
    boxSizing: 'border-box',
    overflowX: 'auto'
  };

  const colunaStyle = {
    backgroundColor: '#ffffff',
    flex: 1,
    minWidth: '260px',
    height: '75vh',
    borderRadius: '6px',
    overflow: 'hidden',
    display: 'flex',
    flexDirection: 'column',
    border: '1px solid #e5e7eb'
  };

  const colunas = [
    { titulo: 'Pedidos', cor: '#3c5262' },
    { titulo: 'Pagamento Confirmado', cor: '#a79261' },
    { titulo: 'Pedido separado', cor: '#ae4f48' },
    { titulo: 'Pedido Enviado', cor: '#252623' },
    { titulo: 'Pedido Entregue', cor: '#3c5262' },
  ];

  const modalOverlayStyle = {
    position: 'fixed',
    top: 0,
    left: 0,
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(37, 38, 35, 0.8)',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000
  };

  const modalContentStyle = {
    backgroundColor: '#f6f0e7',
    padding: '30px',
    borderRadius: '4px',
    width: '400px',
    display: 'flex',
    flexDirection: 'column',
    gap: '15px',
    border: '1px solid #3c5262'
  };

  const inputStyle = {
    padding: '12px',
    borderRadius: '4px',
    border: '1px solid #a79261',
    backgroundColor: '#ffffff',
    color: '#252623',
    fontFamily: 'inherit',
    fontSize: '14px'
  };

  const carregarPedidos = async () => {
    try {
      const response = await fetch(`${URL_CRIAR_PEDIDO}/tarefas`);
      const data = await response.json();
      dispatch(salvarPedidosNoCofre(data));
    } catch (error) {
      console.error("Erro ao buscar tarefas do servidor:", error);
    }
  };

  const carregarCatalogo = async () => {
    try {
      const response = await fetch(`${URL_CONFIGURAR_PRODUTO}/produtos`);
      const data = await response.json();
      setCatalogo(data);
    } catch (error) {
      console.error("Erro ao buscar catálogo:", error);
    }
  };

  useEffect(() => {
    carregarPedidos();
    carregarCatalogo();
  }, []);

  const toggleProduto = (idProduto) => {
    setProdutosSelecionados(prev =>
      prev.includes(idProduto)
        ? prev.filter(id => id !== idProduto)
        : [...prev, idProduto]
    );
  };

  const handleCriarProduto = async () => {
    if (!nomeProduto || !precoProduto) {
      alert("Preencha o nome e o preço do produto.");
      return;
    }

    const novoProduto = { nome: nomeProduto, preco: parseFloat(precoProduto) };

    try {
      const response = await fetch(`${URL_CONFIGURAR_PRODUTO}/produtos`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(novoProduto)
      });

      if (response.ok) {
        setMostrarModalProduto(false);
        setNomeProduto('');
        setPrecoProduto('');
        carregarCatalogo();
      }
    } catch (error) {
      console.error("Erro ao criar produto:", error);
      alert("Não foi possível conectar ao servidor.");
    }
  };

  const handleCriarPedido = async () => {
    if (produtosSelecionados.length === 0) {
      alert("Por favor, selecione pelo menos um produto para o pedido.");
      return;
    }

    const novoPedido = {
      descricao,
      responsavel,
      prioridade,
      produtosIds: produtosSelecionados
    };

    try {
      const response = await fetch(`${URL_CRIAR_PEDIDO}/tarefas`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(novoPedido)
      });

      if (response.ok) {
        setMostrarModal(false);
        setDescricao(''); setResponsavel(''); setPrioridade(3); setProdutosSelecionados([]);
        carregarPedidos();
      }
    } catch (error) {
      console.error("Erro ao conectar:", error);
      alert("Não foi possível conectar ao servidor.");
    }
  };

  return (
    <div style={containerStyle}>

      {mostrarModal && (
        <div style={modalOverlayStyle}>
          <div style={modalContentStyle}>
            <h3 style={{ margin: '0 0 10px 0' }}>Novo Pedido - Velato</h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', border: '1px solid #a79261', padding: '12px', borderRadius: '4px', backgroundColor: '#ffffff', maxHeight: '180px', overflowY: 'auto' }}>
              <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#3c5262' }}>SELECIONE OS PRODUTOS:</label>

              {catalogo.length === 0 ? (
                <span style={{ fontSize: '13px', color: '#9CA3AF' }}>Carregando catálogo...</span>
              ) : (
                catalogo.map(produto => (
                  <label key={produto.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '14px', color: '#252623' }}>
                    <input
                      type="checkbox"
                      checked={produtosSelecionados.includes(produto.id)}
                      onChange={() => toggleProduto(produto.id)}
                      style={{ cursor: 'pointer', width: '16px', height: '16px' }}
                    />
                    {produto.nome} <span style={{ color: '#a79261', fontWeight: 'bold' }}>(R$ {produto.preco})</span>
                  </label>
                ))
              )}
            </div>

            <textarea
              placeholder="Descrição detalhada"
              value={descricao}
              onChange={(e) => setDescricao(e.target.value)}
              style={{ ...inputStyle, minHeight: '80px', resize: 'none' }}
            />

            <input
              placeholder="Responsável"
              value={responsavel}
              onChange={(e) => setResponsavel(e.target.value)}
              style={inputStyle}
            />

            <div style={{ display: 'flex', flexDirection: 'column', gap: '5px' }}>
              <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#3c5262' }}>PRIORIDADE:</label>
              <select
                value={prioridade}
                onChange={(e) => setPrioridade(Number(e.target.value))}
                style={{ ...inputStyle, cursor: 'pointer' }}
              >
                <option value={1}>🔴 Alta (Urgente)</option>
                <option value={2}>🟡 Média (Padrão)</option>
                <option value={3}>🔵 Baixa (Opcional)</option>
              </select>
            </div>

            <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
              <button
                onClick={handleCriarPedido}
                style={{ ...botãoCriarPedido, flex: 1, justifyContent: 'center' }}
              >
                Salvar
              </button>
              <button
                onClick={() => setMostrarModal(false)}
                style={{ flex: 1, backgroundColor: 'transparent', border: '1px solid #E5E7EB', cursor: 'pointer', borderRadius: '4px', fontWeight: '600' }}
              >
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

      {mostrarModalProduto && (
        <div style={modalOverlayStyle}>
          <div style={{ ...modalContentStyle, width: '320px' }}>
            <h3 style={{ margin: '0 0 10px 0' }}>Configurar Produto</h3>

            <input
              placeholder="Nome do produto"
              value={nomeProduto}
              onChange={(e) => setNomeProduto(e.target.value)}
              style={inputStyle}
            />

            <input
              placeholder="Preço (ex: 199.90)"
              type="number"
              value={precoProduto}
              onChange={(e) => setPrecoProduto(e.target.value)}
              style={inputStyle}
            />

            <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
              <button
                onClick={handleCriarProduto}
                style={{ ...botãoCriarPedido, flex: 1, justifyContent: 'center' }}
              >
                Adicionar
              </button>
              <button
                onClick={() => setMostrarModalProduto(false)}
                style={{ flex: 1, backgroundColor: 'transparent', border: '1px solid #E5E7EB', cursor: 'pointer', borderRadius: '4px', fontWeight: '600' }}
              >
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

      <header style={headerVelatoStyle}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: '800', margin: 0, color: '#252623', letterSpacing: '2px' }}>
            VELATO
          </h1>
          <span style={{ fontWeight: '400', color: '#a79261', fontSize: '18px', paddingLeft: '10px', borderLeft: '1px solid #3c5262' }}>
            Orders
          </span>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>

          <button
            style={{
              padding: '10px 24px',
              backgroundColor: 'transparent',
              color: '#3c5262',
              border: '2px solid #3c5262',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: '600',
              fontSize: '14px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}
            onClick={() => window.location.href = 'http://localhost:5174'}
          >
            📊 Ir para o Dashboard
          </button>

          <button style={botãoConfigurarProduto} onClick={() => setMostrarModalProduto(true)}>
            <span style={{ fontSize: '18px', fontWeight: '400' }}>+</span> Configurar Produto
          </button>

          <button style={botãoCriarPedido} onClick={() => setMostrarModal(true)}>
            <span style={{ fontSize: '18px', fontWeight: '400' }}>+</span> Novo Pedido
          </button>
        </div>
      </header>

      <div style={{ padding: '0 40px 20px 40px', display: 'flex', gap: '15px', alignItems: 'center' }}>
        <div style={{ fontWeight: '600', color: '#3c5262', fontSize: '14px' }}>
          Filtrar Pedidos:
        </div>

        <input
          type="text"
          placeholder="Buscar por produto ou responsável..."
          value={termoBusca}
          onChange={(e) => setTermoBusca(e.target.value)}
          style={{ ...inputStyle, width: '300px', padding: '8px 12px' }}
        />

        <select
          value={filtroPrioridade}
          onChange={(e) => setFiltroPrioridade(e.target.value)}
          style={{ ...inputStyle, padding: '8px 12px', cursor: 'pointer' }}
        >
          <option value="TODAS">Todas as Prioridades</option>
          <option value="1"> Alta (Urgente)</option>
          <option value="2"> Média (Padrão)</option>
          <option value="3"> Baixa</option>
        </select>

        {(termoBusca !== '' || filtroPrioridade !== 'TODAS') && (
          <button
            onClick={() => { setTermoBusca(''); setFiltroPrioridade('TODAS'); }}
            style={{ background: 'none', border: 'none', color: '#ae4f48', cursor: 'pointer', fontWeight: 'bold', fontSize: '12px', textDecoration: 'underline' }}
          >
            Limpar Filtros
          </button>
        )}
      </div>

      <div style={kanbanContainerStyle}>
        {colunas.map((col, index) => (
          <div key={index} style={colunaStyle}>

            <div style={{
              padding: '15px',
              textAlign: 'center',
              fontWeight: '700',
              fontSize: '12px',
              textTransform: 'uppercase',
              letterSpacing: '1px',
              backgroundColor: col.cor,
              color: '#FFFFFF'
            }}>
              {col.titulo}
            </div>

            <div style={{ padding: '15px', display: 'flex', flexDirection: 'column', gap: '12px', flex: 1, overflowY: 'auto' }}>

              {pedidos
                .filter((pedido) => pedido.status === col.titulo)
                .filter((pedido) => {
                  if (termoBusca === '') return true;
                  const termo = termoBusca.toLowerCase();
                  return (
                    pedido.titulo.toLowerCase().includes(termo) ||
                    pedido.responsavel.toLowerCase().includes(termo)
                  );
                })
                .filter((pedido) => {
                  if (filtroPrioridade === 'TODAS') return true;
                  return pedido.prioridade === Number(filtroPrioridade);
                })
                .sort((a, b) => a.prioridade - b.prioridade)
                .map((pedido) => (
                  <CardPedido key={pedido.id} pedido={pedido} />
                ))}

            </div>
          </div>
        ))}
      </div>

    </div>
  );
};

export default App;
