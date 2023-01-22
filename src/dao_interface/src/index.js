import Alpine from 'alpinejs'

// Imports and re-exports candid interface
//import { dao_backend } from "../../declarations/dao_backend";
import { idlFactory, canisterId, dao_backend } from "../../declarations/dao_backend";

window.Alpine = Alpine

// display all errors
window.onerror = function (e, url, line) {
    let el = document.getElementById('errors');
    el.innerText = e;
}

window.clearErrors = function () {
    let el = document.getElementById('errors');
    el.innerText = "";
}

// Functions to interact with DAO
let dao = {
    backend: dao_backend,
    plug_connected: false,
    plug_available: !!window.ic?.plug,
};
window.dao = dao;

const nnsCanisterIds = [
    //TODO: add MB token canister to whitelist
];


//Alpine.store('darkMode', { on: false, toggle() { this.on = !this.on } })
//Alpine.data('backend', dao_backend);
Alpine.store('dao', {
    draft: '',
    proposals: [],
    mb_balance: 0,
    submit_status: { ok: 0 },
    lock: false,
    plug_available: !!window.ic?.plug,
    backend: dao_backend,

    plug_connect: async function () {
        if (!this.plug_available) throw "Plug not installed"

        let plug = window.ic.plug;

        let pubKey = await plug.requestConnect();

        this.backend = await plug.createActor({ canisterId: canisterId, interfaceFactory: idlFactory });
        this.plug_connected = true;

        return true;
    },

    async assertPlug() {
        if (!this.plug_connected) await this.plug_connect();

        if (!this.plug_connected) throw "Plug not connected";
        else console.log("Plug is connected")
    },

    async updateProposals() {
        this.proposals = [];
        this.proposals = await this.backend.getProposals(-100, 100);
    },

    async submitProposal() {
        await this.assertPlug();

        this.submit_status = await this.backend.submitProposal(this.draft);
        this.draft = '';
        this.proposals = [];
        this.proposals = await this.backend.getProposals(-100, 100);
    },

    async vote(proposal, support) {
        await this.assertPlug();

        let vote = { reject: null };
        if (support) {
            vote = { support: null }
        }
        let res = await this.backend.vote(proposal, vote);
        if (Object.keys(res)[0] !== "ok") {
            throw "Vote failed " + JSON.stringify(res);
        }
    },

    async updateBalance() {
        this.mb_balance = 0.0;
        await this.assertPlug();

        let res = await this.backend.callerBalance();
        this.mb_balance = res / BigInt(10 ** 8);
    },

    async init() {
        await this.updateProposals();
    },
});

Alpine.store('darkMode', {
    on: false,

    toggle() {
        this.on = !this.on
    }
})

Alpine.start();

Alpine.store("dao").init();
