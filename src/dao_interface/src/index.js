import { dao_backend } from "../../declarations/dao_backend";
import Alpine from 'alpinejs'

window.Alpine = Alpine

//Alpine.store('darkMode', { on: false, toggle() { this.on = !this.on } })
//Alpine.data('backend', dao_backend);
Alpine.start();

window.backend = dao_backend;
