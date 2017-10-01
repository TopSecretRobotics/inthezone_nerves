// === DEFAULT / CUSTOM STYLE ===
// WARNING! always comment out ONE of the two require() calls below.
// 1. use next line to activate CUSTOM STYLE (./src/themes)
// require(`./themes/app.${__THEME}.styl`)
// 2. or, use next line to activate DEFAULT QUASAR STYLE
require(`quasar/dist/quasar.${__THEME}.css`)
// ==============================

// Uncomment the following lines if you need IE11/Edge support
// require(`quasar/dist/quasar.ie`)
// require(`quasar/dist/quasar.ie.${__THEME}.css`)

import Vue from 'vue'
import Quasar from 'quasar'
import router from './configs/router'

Vue.config.productionTip = false
Vue.use(Quasar) // Install Quasar Framework

import VueApollo from 'vue-apollo'
import apolloProvider from './configs/apollo'
Vue.use(VueApollo)

import VueMoment from 'vue-moment'
Vue.use(VueMoment)

import VueNonreactive from 'vue-nonreactive'
Vue.use(VueNonreactive)

if (__THEME === 'mat') {
  require('quasar-extras/roboto-font')
}
import 'quasar-extras/material-icons'
// import 'quasar-extras/ionicons'
// import 'quasar-extras/fontawesome'
// import 'quasar-extras/animate'

import 'vue-virtual-scroller/dist/vue-virtual-scroller.css'

Quasar.start(() => {
  /* eslint-disable no-new */
  return new Vue({
    el: '#q-app',
    apolloProvider,
    router,
    render: h => h(require('./App'))
  })
})
