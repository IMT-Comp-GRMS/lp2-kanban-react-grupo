import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { salvarPedidosNoCofre } from './store/pedidosSlice';

/* ==========================================================================
   URLS DA API — Kubernetes (NodePort)
   ========================================================================== */
const URL_CRIAR_PEDIDO = 'http://localhost:30991'; // era :3000
const URL_HISTORICO = 'http://localhost:30946';    // era :5001

const CardPedido = ({ pedido }) => {
  const dispatch = useDispatch();

  const [historico, setHistorico] = useState([]);
  const [mostrarHistorico, setMostrarHistorico] = useState(false);
  const [carregandoHistorico, setCarregandoHistorico] = useState(false);

  const ordemColunas = [
    'Pedidos',
    'Pagamento Confirmado',
    'Pedido separado',
    'Pedido Enviado',
    'Pedido Entregue'
  ];

  const atualizarStatus = async (novoStatus) => {
    try {
      const response = await fetch(`${URL_CRIAR_PEDIDO}/tarefas/${pedido.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: novoStatus, status_anterior: pedido.status })
      });

      if (response.ok) {
        const resLista = await fetch(`${URL_CRIAR_PEDIDO}/tarefas`);
        const listaAtualizada = await resLista.json();
        dispatch(salvarPedidosNoCofre(listaAtualizada));
      }
    } catch (error) {
      console.error("Erro ao mover pedido:", error);
    }
  };

  const handleVerHistorico = async () => {
    if (mostrarHistorico) {
      setMostrarHistorico(false);
      return;
    }

    setCarregandoHistorico(true);
    try {
      const response = await fetch(`${URL_HISTORICO}/historico/${pedido.id}`);

      if (response.ok) {
        const data = await response.json();
        setHistorico(data);
      } else {
        setHistorico([]);
      }
    } catch (error) {
      console.error("Erro ao buscar histórico:", error);
      setHistorico([]);
    }
    setCarregandoHistorico(false);
    setMostrarHistorico(true);
  };

  const indexAtual = ordemColunas.indexOf(pedido.status);

  const handleAvancar = () => {
    if (indexAtual < ordemColunas.length - 1) {
      atualizarStatus(ordemColunas[indexAtual + 1]);
    }
  };

  const handleVoltar = () => {
    if (indexAtual > 0) {
      atualizarStatus(ordemColunas[indexAtual - 1]);
    }
  };

  const handleExcluir = async () => {
    if (window.confirm(`Tem certeza que deseja excluir o pedido "${pedido.titulo}"?`)) {
      try {
        const response = await fetch(`${URL_CRIAR_PEDIDO}/tarefas/${pedido.id}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          const resLista = await fetch(`${URL_CRIAR_PEDIDO}/tarefas`);
          const listaAtualizada = await resLista.json();
          dispatch(salvarPedidosNoCofre(listaAtualizada));
        }
      } catch (error) {
        console.error("Erro ao excluir:", error);
      }
    }
  };

  const coresPrioridade = {
    1: '#ae4f48',
    2: '#a79261',
    3: '#3c5262'
  };

  const cardStyle = {
    backgroundColor: '#FFFFFF',
    padding: '15px',
    borderRadius: '4px',
    borderLeft: `6px solid ${coresPrioridade[pedido.prioridade] || '#3c5262'}`,
    borderBottom: '1px solid #E5E7EB',
    borderRight: '1px solid #E5E7EB',
    borderTop: '1px solid #E5E7EB',
    position: 'relative',
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
    cursor: 'pointer'
  };

  const botaoStyle = {
    flex: 1,
    padding: '5px',
    fontSize: '11px',
    fontWeight: 'bold',
    cursor: 'pointer',
    border: '1px solid #3c5262',
    backgroundColor: 'transparent',
    color: '#3c5262',
    borderRadius: '2px'
  };

  return (
    <div style={cardStyle}>
      <button
        onClick={handleExcluir}
        style={{
          position: 'absolute',
          top: '8px',
          right: '8px',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          fontSize: '16px',
          color: '#ae4f48',
          zIndex: 10
        }}
        title="Excluir Pedido"
      >
        🗑️
      </button>

      <div style={{ fontSize: '12px', fontWeight: 'bold', color: '#071227' }}>
        ID: {pedido.id}
      </div>

      <div style={{ fontWeight: '700', fontSize: '14px', paddingRight: '20px' }}>
        {pedido.titulo}
      </div>

      <div style={{ fontSize: '12px', color: '#6B7280' }}>
        {pedido.descricao}
      </div>

      <div style={{ fontSize: '11px', fontWeight: 'bold', color: '#a79261' }}>
        Responsável: {pedido.responsavel}
      </div>

      <div style={{ display: 'flex', gap: '5px', marginTop: '10px' }}>
        {indexAtual > 0 && (
          <button onClick={handleVoltar} style={botaoStyle}> ⬅ Voltar </button>
        )}

        {indexAtual < ordemColunas.length - 1 && (
          <button
            onClick={handleAvancar}
            style={{ ...botaoStyle, backgroundColor: '#3c5262', color: '#f6f0e7' }}
          >
            Avançar ➡
          </button>
        )}
      </div>

      <button
        onClick={handleVerHistorico}
        style={{
          ...botaoStyle,
          backgroundColor: mostrarHistorico ? '#a79261' : 'transparent',
          color: mostrarHistorico ? '#f6f0e7' : '#a79261',
          border: '1px solid #a79261',
          width: '100%'
        }}
      >
        {carregandoHistorico ? 'Carregando...' : mostrarHistorico ? '▲ Fechar Histórico' : '📋 Ver Histórico'}
      </button>

      {mostrarHistorico && (
        <div style={{ marginTop: '5px' }}>
          {historico.length === 0 ? (
            <p style={{ fontSize: '12px', color: '#9CA3AF', textAlign: 'center' }}>
              Nenhuma movimentação registrada.
            </p>
          ) : (
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '11px' }}>
              <thead>
                <tr style={{ backgroundColor: '#f6f0e7' }}>
                  <th style={{ padding: '5px', textAlign: 'left', borderBottom: '1px solid #E5E7EB', color: '#3c5262' }}>De</th>
                  <th style={{ padding: '5px', textAlign: 'left', borderBottom: '1px solid #E5E7EB', color: '#3c5262' }}>Para</th>
                  <th style={{ padding: '5px', textAlign: 'left', borderBottom: '1px solid #E5E7EB', color: '#3c5262' }}>Data/Hora</th>
                </tr>
              </thead>
              <tbody>
                {historico.map((linha) => (
                  <tr key={linha.id} style={{ borderBottom: '1px solid #f6f0e7' }}>
                    <td style={{ padding: '5px', color: '#ae4f48' }}>{linha.status_anterior || '—'}</td>
                    <td style={{ padding: '5px', color: '#3c5262' }}>{linha.status_novo}</td>
                    <td style={{ padding: '5px', color: '#6B7280' }}>{linha.data_hora}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
};

export default CardPedido;
