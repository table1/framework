import { createRouter, createWebHashHistory } from 'vue-router'
import DocsCategoryView from './views/DocsCategoryView.vue'
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
    redirect: '/docs/category/1'
  },
  {
    path: '/docs/category/:categoryId',
    name: 'docs-category',
    component: DocsCategoryView,
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
