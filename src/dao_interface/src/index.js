import Alpine from 'alpinejs'
import moment from 'moment';

// Imports and re-exports candid interface
import { idlFactory, canisterId, dao_backend } from "../../declarations/dao_backend";

import { idlFactory as icrc1 } from "./icrc1.did";

const mbTokenId = "db3eq-6iaaa-aaaah-abz6a-cai";

window.Alpine = Alpine;
window.moment = moment;

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
    mb_balance: "-",
    neuron: {},
    //{
    //    amount: 12,
    //    dissolving: false,
    //    age: 10 * (10 ** 9),
    //    delay: 100 * (10 ** 9)
    //},
    lockFor: 0.001,
    amount: 1.0,
    submit_status: { ok: 0 },
    lock: false,
    plug_available: !!window.ic?.plug,
    backend: dao_backend,
    mbToken: null,

    plug_connect: async function () {
        if (!this.plug_available) throw "Plug not installed"

        let plug = window.ic.plug;

        let pubKey = await plug.requestConnect();

        this.backend = await plug.createActor({ canisterId: canisterId, interfaceFactory: idlFactory });
        this.plug_connected = true;

        this.mbToken = await plug.createActor({ canisterId: mbTokenId, interfaceFactory: icrc1 });

        // update balance and neuron (async, without await)
        this.updateBalance();
        this.getNeuron();

        return true;
    },

    async assertPlug() {
        if (!this.plug_connected) await this.plug_connect();

        if (!this.plug_connected) throw "Plug not connected";
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
        await this.updateProposals();
    },

    async updateBalance() {
        this.mb_balance = "-";
        await this.assertPlug();
        let res = await this.backend.callerBalance();
        this.mb_balance = Number(res) / 100_000_000;
    },

    async getNeuron() {
        await this.assertPlug();
        console.log("get neuron");
        let neuron = await this.backend.getNeuron();
        this.neuron = neuron[0];
        console.log("get neuron returned:", neuron);
    },

    getAmount() {
        let amount = parseFloat(this.amount) || 0;
        return Math.floor(amount * 100_000_000);
    },

    getDelay() {
        let time = parseFloat(this.lockFor) || 0;
        return Math.floor(time * 24 * 60 * 60 * 1000000000);
    },

    getNeuronAmount() {
        return this.neuron?.amount
    },

    async createNeuron() {
        await this.assertPlug();
        let amount = this.getAmount()
        let args = await this.backend.getTransferArgs(amount)
        let res = await this.mbToken.icrc1_transfer(args);
        console.log("transfer result:", res);
        let delay = this.getDelay();
        let result = await this.backend.createNeuron(amount, delay);
        console.log("create neuron returned:", result);

        this.updateBalance();
        this.getNeuron();
    },

    async lockNeuron() {
        await this.assertPlug();
        await this.backend.lockNeuron(this.getDelay());
        this.getNeuron();
    },

    async dissolveNeuron() {
        await this.assertPlug();
        await this.backend.dissolveNeuron();
        this.getNeuron();
    },

    async disburseNeuron() {
        await this.assertPlug();
        await this.backend.disburseNeuron();
        this.getNeuron();
    },

    async topUpNeuron() {
        await this.assertPlug();
        let amount = this.getAmount()
        let args = await this.backend.getTransferArgs(amount)
        let res = await this.mbToken.icrc1_transfer(args);
        console.log("transfer result:", res);
        await this.backend.topUpNeuron(amount);
        this.getNeuron();
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
