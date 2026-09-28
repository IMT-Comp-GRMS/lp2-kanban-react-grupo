/**
 * ============================================================================
 * CAMADA DE DADOS - Dashboard Velato
 * ============================================================================
 * Cada função exportada busca um conjunto de dados do microsserviço
 * Dashboard rodando no Kubernetes (Service dashboard-service, NodePort)
 * ============================================================================
 */

const BASE_URL = 'http://localhost:30795'; // era :4000

/**
 * Busca os KPIs principais para os cards do topo.
 * @returns {{ totalPedidos, entreguesHoje, urgentesAberto, totalProdutos }}
 */
export async function buscarKpis() {
  const response = await fetch(`${BASE_URL}/dashboard/kpis`);
  return response.json();
}

/**
 * Busca o volume de pedidos criados por dia (últimos 7 dias).
 * @returns {Array<{ data: string, pedidos: number }>}
 */
export async function buscarVolumeDiario() {
  const response = await fetch(`${BASE_URL}/dashboard/volume-diario`);
  return response.json();
}

/**
 * Busca o ranking de produtos que mais aparecem nos pedidos.
 * @returns {Array<{ nome: string, pedidos: number }>}
 */
export async function buscarProdutosMaisPedidos() {
  const response = await fetch(`${BASE_URL}/dashboard/produtos-mais-pedidos`);
  return response.json();
}