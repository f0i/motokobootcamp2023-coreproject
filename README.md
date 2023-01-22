# Motoko Bootcamp 2023 Core Project

This projects implements a DAO to control the content of a webpage.

It is part of the Motoko Bootcamp 2023.

Requirements are listed in [motoko-bootcamp/motokobootcamp-2023](https://github.com/motoko-bootcamp/motokobootcamp-2023/blob/main/core_project/PROJECT.MD)
and summarized in this document, as well as additional requirements and features.

## DAO Webpage

<https://667zg-iqaaa-aaaah-ab4ha-cai.ic0.app> (without `.raw` \o/ )

This is a webpage served by a motoko canister.
The content is controlled by the DAO.

### Webpage functionality

- Serve the current text on HTTP requests
- Update current text
  - Check if call is coming from DAO Backend

## DAO Backend

<https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=6x4s2-6yaaa-aaaah-ab4gq-cai> (Candid UI)

This contains the ledger of proposals, tracks votes and, when voting period is over, push updates to the webpage canister.

### Backend functionality

The container provides the following functionality:

- Create proposals
  - Checks if user is authorized
- Vote on proposals
  - Checks if user has MB tokens
  - Calculate voting power
- Execute voting result
  - Push text to DAO Webpage

## DAO Interface

<https://6z67s-fiaaa-aaaah-ab4hq-cai.ic0.app>

This provides a user friendly interface for creating proposals and for voting.

### Interface functionality

- UI for creating proposals
- UI for listing proposals
- UI for voting on proposals

## `dfx` commands

### local

```bash
dfx identity use default
dfx deploy # deploy to local replica, will show links to Candid UI
dfx generate # generate declarations

./test.sh # run local tests
```

### IC

```bash
dfx identity use test2021
dfx wallet --network ic balance

# Create canister on IC
dfx canister --network ic create dao_backend --with-cycles 1000000000000 --controller xlesp-lrnfo-bihzg-l5rwa-c2h2r-vukct-pjab5-rj5f7-6664l-uu6qx-cae
# repeat for each canister

# update the canister
dfx generate --network ic
dfx build --network ic
dfx canister --network ic install --mode auto dao_interface

# or in one line
dfx generate --network ic && dfx build --network ic && dfx canister --network ic install --mode auto dao_interface
```

## Links and Resources

Github: <https://github.com/f0i>

Core project: <https://github.com/f0i/motokobootcamp2023-coreproject>

Motoko challenges: <https://github.com/f0i/motokobootcamp2023>

Custom domain: <https://internetcomputer.org/docs/current/developer-docs/deploy/custom-domain#creating-the-custom-service-worker>
