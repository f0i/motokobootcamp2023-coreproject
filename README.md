# Motoko Bootcamp 2023 Core Project

This projects implements a DAO to control the content of a webpage.

It is part of the Motoko Bootcamp 2023.

Requirements are listed in [motoko-bootcamp/motokobootcamp-2023](https://github.com/motoko-bootcamp/motokobootcamp-2023/blob/main/core_project/PROJECT.MD)
and summarized in this document, as well as additional requirements and features.

## DAO Webpage

This is a webpage served by a motoko canister.
The content is controlled by the DAO.

### Webpage functionality

- Serve the current text on HTTP requests
- Update current text
  - Check if call is coming from DAO Backend

## DAO Backend

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

#Create canister on IC
dfx canister --network ic create dao_backend --with-cycles 1000000000000 --controller xlesp-lrnfo-bihzg-l5rwa-c2h2r-vukct-pjab5-rj5f7-6664l-uu6qx-cae
pw=insertYourDfxPassword dfx build --network ic
dfx canister --network ic install dao_backend
```

## Links and Resources

Custom domain: <https://internetcomputer.org/docs/current/developer-docs/deploy/custom-domain#creating-the-custom-service-worker>
