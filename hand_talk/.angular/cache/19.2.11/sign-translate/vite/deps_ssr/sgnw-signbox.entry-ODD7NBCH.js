import { createRequire } from 'module';const require = createRequire(import.meta.url);
import {
  overlap
} from "./chunk-VV74EUNO.js";
import {
  Host,
  getElement,
  h,
  registerInstance
} from "./chunk-CC4NM3P7.js";
import "./chunk-5P6RLSS7.js";

// node_modules/@sutton-signwriting/sgnw-components/dist/esm/sgnw-signbox.entry.js
var sgnwSignboxCss = ".sc-sgnw-signbox-h{width:100%;height:100%;border-radius:10px;display:block}";
var SgnwSignbox = class {
  constructor(hostRef) {
    registerInstance(this, hostRef);
  }
  paletteSymbolDropHandler(event) {
    const target = event.target;
    if (overlap(target, this.el)) {
      console.log(event.detail);
    }
  }
  render() {
    return h(Host, null, h("slot", null));
  }
  get el() {
    return getElement(this);
  }
};
SgnwSignbox.style = sgnwSignboxCss;
export {
  SgnwSignbox as sgnw_signbox
};
/*! Bundled license information:

@sutton-signwriting/sgnw-components/dist/esm/sgnw-signbox.entry.js:
  (*!
   * The Sutton SignWriting Web Components
   *)
*/
//# sourceMappingURL=sgnw-signbox.entry-ODD7NBCH.js.map
