import Alpine from 'alpinejs'

// Imports and re-exports candid interface
//import { dao_backend } from "../../declarations/dao_backend";
import { idlFactory, canisterId, dao_backend } from "../../declarations/dao_backend";

window.Alpine = Alpine

let dao = {
    backend: dao_backend,
    plug_connected: false,
    plug_available: !!(window.ic && window.ic.plug),
};
window.dao = dao;


//Alpine.store('darkMode', { on: false, toggle() { this.on = !this.on } })
//Alpine.data('backend', dao_backend);
Alpine.start();


const nnsCanisterIds = [];

dao.plug_connect = async function () {
    let plug = window.ic.plug;

    let pubKey = await plug.requestConnect();

    dao.backend_plug = await plug.createActor({ canisterId: canisterId, interfaceFactory: idlFactory });
    dao.plug_connected = true;

    await window.dao.backend.getProposals(0, 10).then(console.log, console.error)

    await window.dao.backend_plug.getProposals(0, 10).then(console.log, console.error)
}

// display all errors
window.onerror = function (e, url, line) {
    dao.errorMsg = e;
}