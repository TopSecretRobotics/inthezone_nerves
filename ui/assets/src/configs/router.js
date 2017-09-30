import Vue from 'vue'
import VueRouter from 'vue-router'

Vue.use(VueRouter)

function load (component) {
  // '@' is aliased to src/components
  return () => import(`@/${component}.vue`)
}

export default new VueRouter({
  /*
   * NOTE! VueRouter "history" mode DOESN'T works for Cordova builds,
   * it is only to be used only for websites.
   *
   * If you decide to go with "history" mode, please also open /config/index.js
   * and set "build.publicPath" to something other than an empty string.
   * Example: '/' instead of current ''
   *
   * If switching back to default "hash" mode, don't forget to set the
   * build publicPath back to '' so Cordova builds work again.
   */

  // mode: 'history',
  routes: [
    { path: '/', component: load('Dashboard'), name: 'dashboard' },
    {
      path: '/motors',
      component: load('Motors'),
      children: [
        { path: '', component: load('Motors/Overview'), name: 'motors' },
        { path: 'graph', component: load('Motors/Graph'), name: 'motorsGraph' }
      ]
    },
    {
      path: '/drive',
      component: load('Drive'),
      children: [
        { path: '', component: load('Drive/Control'), name: 'drive' },
        { path: 'setup', component: load('Drive/Setup'), name: 'driveSetup' }
      ]
    },
    {
      path: '/vcr',
      component: load('VCR'),
      children: [
        { path: '', component: load('VCR/Cassettes'), name: 'vcr' },
        { path: 'cassette/:cassetteId', component: load('VCR/Cassette'), props: true, name: 'vcrCassette' }
      ]
    },
    {
      path: '/debug',
      component: load('Debug'),
      children: [
        { path: '', component: load('Debug/Home'), name: 'debug' },
        { path: 'local-server', component: load('Debug/LocalServer'), name: 'debugLocalServer' },
        { path: 'local-socket', component: load('Debug/LocalSocket'), name: 'debugLocalSocket' },
        { path: 'robot-server', component: load('Debug/RobotServer'), name: 'debugRobotServer' },
        { path: 'robot-socket', component: load('Debug/RobotSocket'), name: 'debugRobotSocket' }
      ]
    },

    // Always leave this last one
    { path: '*', component: load('Error404') } // Not found
  ]
})
