/**
 * ============================================================================
 * CAMADA DE DADOS - Dashboard Velato
 * ============================================================================
 * Cada função exportada busca um conjunto de dados do microsserviço
 * Dashboard rodando no Kubernetes (Service dashboard-service, NodePort)
 * ============================================================================
 */

const BASE_URL = 'http://localhost:30004'; // nodePort do dashboard-service

/**
 * Faz o GET e lança erro se o serviço responder com status de falha (ex.: 500),
 * para o App.jsx mostrar a mensagem de erro em vez de tratar o corpo como dado.
 */
async function buscarJson(caminho) {
  const response = await fetch(`${BASE_URL}${caminho}`);
  if (!response.ok) {
    throw new Error(`Falha ao buscar ${caminho}: ${response.status}`);
  }
  return response.json();
}

/**
 * Busca os KPIs principais para os cards do topo.
 * @returns {{ totalPedidos, entreguesHoje, urgentesAberto, totalProdutos }}
 */
export async function buscarKpis() {
  return buscarJson('/dashboard/kpis');
}

/**
 * Busca o volume de pedidos criados por dia (últimos 7 dias).
 * @returns {Array<{ data: string, pedidos: number }>}
 */
export async function buscarVolumeDiario() {
  return buscarJson('/dashboard/volume-diario');
}

/**
 * Busca o ranking de produtos que mais aparecem nos pedidos.
 * @returns {Array<{ nome: string, pedidos: number }>}
 */
export async function buscarProdutosMaisPedidos() {
  return buscarJson('/dashboard/produtos-mais-pedidos');
}
