import { createRequire } from 'module';const require = createRequire(import.meta.url);
import {
  registerPlugin
} from "./chunk-CCBP4DRQ.js";
import {
  __async
} from "./chunk-5P6RLSS7.js";

// node_modules/@capacitor/synapse/dist/synapse.mjs
function s(t) {
  t.CapacitorUtils.Synapse = new Proxy({}, {
    get(e, n) {
      return new Proxy({}, {
        get(w, o) {
          return (c, p, r) => {
            const i = t.Capacitor.Plugins[n];
            if (i === void 0) {
              r(new Error(`Capacitor plugin ${n} not found`));
              return;
            }
            if (typeof i[o] != "function") {
              r(new Error(`Method ${o} not found in Capacitor plugin ${n}`));
              return;
            }
            (() => __async(null, null, function* () {
              try {
                const a = yield i[o](c);
                p(a);
              } catch (a) {
                r(a);
              }
            }))();
          };
        }
      });
    }
  });
}
function u(t) {
  t.CapacitorUtils.Synapse = new Proxy({}, {
    get(e, n) {
      return t.cordova.plugins[n];
    }
  });
}
function f(t = false) {
  typeof window > "u" || (window.CapacitorUtils = window.CapacitorUtils || {}, window.Capacitor !== void 0 && !t ? s(window) : window.cordova !== void 0 && u(window));
}

// node_modules/@capacitor/filesystem/dist/esm/index.js
var Filesystem = registerPlugin("Filesystem", {
  web: () => import("./web-RQB7LHSX.js").then((m) => new m.FilesystemWeb())
});
f();

export {
  Filesystem
};
//# sourceMappingURL=chunk-K7MLR3SJ.js.map
