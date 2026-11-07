/**
 * ============================================================================
 * APP PRINCIPAL — Dashboard Velato
 * ============================================================================
 * Orquestra o carregamento dos dados (via dashboardService) e compõe
 * o layout completo do painel de análises.
 *
 * Estrutura visual:
 *   1. Header (identidade Velato + link para o Kanban)
 *   2. Linha de KPI Cards (métricas rápidas)
 *   3. Grid de gráficos: Volume Diário | Produtos Mais Pedidos
 * ============================================================================
 */
import { useState, useEffect } from 'react';
import KpiCard from './components/KpiCard';
import GraficoVolumeDiario from './components/GraficoVolumeDiario';
import GraficoProdutos from './components/GraficoProdutos';

import {
  buscarKpis,
  buscarVolumeDiario,
  buscarProdutosMaisPedidos,
} from './api/dashboardService';

const App = () => {
  /* ==========================================================================
     ESTADOS
     ========================================================================== */
  const [kpis, setKpis] = useState(null);
  const [volumeDiario, setVolumeDiario] = useState([]);
  const [produtosMaisPedidos, setProdutosMaisPedidos] = useState([]);
  const [carregando, setCarregando] = useState(true);
  // true quando a busca falhou (ex.: serviço Dashboard fora do ar). Antes, o
  // erro só ia para o console e a página quebrava ao ler kpis.totalPedidos.
  const [erro, setErro] = useState(false);

  /* ==========================================================================
     CARREGAMENTO DE DADOS
     ========================================================================== */
  // Fora do useEffect para o botão "Tentar novamente" poder chamar de novo.
  async function carregarDados() {
    setCarregando(true);
    setErro(false);
    try {
      // Todas as chamadas em paralelo para máxima performance
      const [dadosKpis, dadosVolume, dadosProdutos] = await Promise.all([
        buscarKpis(),
        buscarVolumeDiario(),
        buscarProdutosMaisPedidos(),
      ]);
      setKpis(dadosKpis);
      setVolumeDiario(dadosVolume);
      setProdutosMaisPedidos(dadosProdutos);
    } catch (erro) {
      console.error('Erro ao carregar dados do dashboard:', erro);
      setErro(true);
    } finally {
      setCarregando(false);
    }
  }

  useEffect(() => {
    carregarDados();
  }, []);

  /* ==========================================================================
     ESTILOS (paleta Velato)
     ========================================================================== */
  const containerStyle = {
    backgroundColor: '#f6f0e7',
    minHeight: '100vh',
    fontFamily: "'Inter', 'Helvetica Neue', Helvetica, Arial, sans-serif",
    color: '#252623',
  };

  const headerStyle = {
    backgroundColor: '#f6f0e7',
    padding: '20px 40px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottom: '2px solid #3c5262',
    marginBottom: '30px',
  };

  const logoStyle = {
    display: 'flex',
    alignItems: 'center',
    gap: '15px',
  };

  const mainStyle = {
    padding: '0 40px 40px 40px',
    display: 'flex',
    flexDirection: 'column',
    gap: '24px',
  };

  const kpiRowStyle = {
    display: 'flex',
    gap: '16px',
    flexWrap: 'wrap',
  };

  const chartsRowStyle = {
    display: 'flex',
    gap: '16px',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
  };

  const linkKanbanStyle = {
    padding: '8px 20px',
    backgroundColor: 'transparent',
    border: '1px solid #3c5262',
    color: '#3c5262',
    borderRadius: '4px',
    cursor: 'pointer',
    fontWeight: '600',
    fontSize: '13px',
    textDecoration: 'none',
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
  };

  /* ==========================================================================
     RENDERIZAÇÃO
     ========================================================================== */
  if (carregando) {
    return (
      <div style={{ ...containerStyle, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ fontSize: '18px', color: '#3c5262', fontWeight: '600' }}>
          Carregando dashboard...
        </div>
      </div>
    );
  }

  // Falha na busca: mensagem e botão para tentar de novo, como a tela de
  // Dashboard do app Flutter já faz.
  if (erro || !kpis) {
    return (
      <div style={{ ...containerStyle, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '12px' }}>
        <div style={{ fontSize: '16px', color: '#ae4f48', fontWeight: '600' }}>
          Não foi possível carregar o dashboard. Verifique se o serviço está no ar.
        </div>
        <button
          onClick={carregarDados}
          style={{ padding: '8px 20px', backgroundColor: '#3c5262', color: '#ffffff', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: '600', fontSize: '14px' }}
        >
          Tentar novamente
        </button>
      </div>
    );
  }

  return (
    <div style={containerStyle}>

      {/* ---- HEADER ---- */}
      <header style={headerStyle}>
        <div style={logoStyle}>
          <h1 style={{ fontSize: '28px', fontWeight: '800', margin: 0, color: '#252623', letterSpacing: '2px' }}>
            VELATO
          </h1>
          <span style={{ fontWeight: '400', color: '#a79261', fontSize: '18px', paddingLeft: '10px', borderLeft: '1px solid #3c5262' }}>
            Dashboard
          </span>
        </div>

        {/* Link de volta para o Kanban (porta 5173) */}
        <a href="http://localhost:5173" style={linkKanbanStyle}>
          ← Ver Kanban
        </a>
      </header>

      {/* ---- CONTEÚDO PRINCIPAL ---- */}
      <main style={mainStyle}>

        {/* ---- LINHA DE KPI CARDS ---- */}
        <div style={kpiRowStyle}>
          <KpiCard
            icone="📦"
            titulo="Total de Pedidos"
            valor={kpis.totalPedidos}
            corDestaque="#3c5262"
          />
          <KpiCard
            icone="✅"
            titulo="Entregues Hoje"
            valor={kpis.entreguesHoje}
            corDestaque="#a79261"
          />
          <KpiCard
            icone="🔴"
            titulo="Urgentes em Aberto"
            valor={kpis.urgentesAberto}
            corDestaque="#ae4f48"
          />
          <KpiCard
            icone="🛍️"
            titulo="Produtos no Catálogo"
            valor={kpis.totalProdutos}
            corDestaque="#2e1172"
          />
        </div>

        {/* ---- LINHA DE GRÁFICOS ---- */}
        <div style={chartsRowStyle}>
          <GraficoVolumeDiario dados={volumeDiario} />
          <GraficoProdutos dados={produtosMaisPedidos} />
        </div>

      </main>
    </div>
  );
};

export default App;
