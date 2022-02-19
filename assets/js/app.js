// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"
import Alpine from 'alpinejs'

import InfiniteScroll from './hooks/infinitescroll.js';

// Initialize alpine
window.Alpine = Alpine
 
Alpine.start()


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { InfiniteScroll },
  // Make liveviews work together with alpine
  dom: {
    onBeforeElUpdated(from, to) {
      // Alpine v3
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  },
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
const colorAncillary = getComputedStyle(document.documentElement)
  .getPropertyValue('--color-ancillary');
topbar.config({barColors: {0: colorAncillary}, shadowColor: "rgba(0, 0, 0, .3)"})

// Do not immediately show loader, actions are perceived faster this way.
// https://hexdocs.pm/phoenix_live_view/installation.html#progress-animation
let topBarScheduled = undefined

window.addEventListener("phx:page-loading-start", () => {
  if(!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 200)
  }
})

window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled)
  topBarScheduled = undefined
  topbar.hide()
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

