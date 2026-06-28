import { createRouter, createWebHashHistory } from 'vue-router'
import DashboardView from './views/DashboardView.vue'
import SurveyInputView from './views/SurveyInputView.vue'
import HistoryView from './views/HistoryView.vue'

const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: DashboardView
  },
  {
    path: '/survey',
    name: 'survey',
    component: SurveyInputView
  },
  {
    path: '/history',
    name: 'history',
    component: HistoryView
  }
]

export const router = createRouter({
  history: createWebHashHistory(),
  routes
})
export default router
