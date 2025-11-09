import { createRouter, createWebHashHistory } from 'vue-router'
import DocsView from './views/DocsView.vue'
import ProjectsView from './views/ProjectsView.vue'
import NewProjectView from './views/NewProjectView.vue'
import ProjectDetailView from './views/ProjectDetailView.vue'
import SettingsView from './views/SettingsView.vue'
import ProjectPackagesView from './views/ProjectPackagesView.vue'
import ProjectDataView from './views/ProjectDataView.vue'
import ProjectConnectionsView from './views/ProjectConnectionsView.vue'

const routes = [
  {
    path: '/',
    redirect: '/projects'
  },
  {
    path: '/docs',
    name: 'docs',
    component: DocsView
  },
  {
    path: '/docs/:functionName',
    name: 'doc-detail',
    component: DocsView,
    props: true
  },
  {
    path: '/projects',
    name: 'projects',
    component: ProjectsView
  },
  {
    path: '/projects/new',
    name: 'project-create',
    component: NewProjectView
  },
  {
    path: '/project/:id',
    name: 'project-detail',
    component: ProjectDetailView,
    props: true
  },
  {
    path: '/settings/:section?/:subsection?',
    name: 'settings',
    component: SettingsView,
    props: true
  },
  {
    path: '/project/packages',
    name: 'project-packages',
    component: ProjectPackagesView
  },
  {
    path: '/project/data',
    name: 'project-data',
    component: ProjectDataView
  },
  {
    path: '/project/connections',
    name: 'project-connections',
    component: ProjectConnectionsView
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

export default router
