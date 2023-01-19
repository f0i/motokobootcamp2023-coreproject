# Motoko Bootcamp 2023 Core Project

This projects implements a DAO to control the content of a webpage.

It is part of the Motoko Bootcamp 2023.

Requirements are listed in [motoko-bootcamp/motokobootcamp-2023](https://github.com/motoko-bootcamp/motokobootcamp-2023/blob/main/core_project/PROJECT.MD)
and summarized in this document, as well as additional requirements and features.

## DAO Webpage

This is a webpage served by a motoko canister.
The content is controlled by the DAO.

## DAO Backend

This contains the ledger of proposals, tracks votes and, when voting period is over, push updates to the webpage canister.

### Functionality

The container provides the following functionality:

- Create proposals
  - Checks if user is authorized

## DAO Interface

This provides a user friendly interface for creating proposals and for voting.

## Links

Custom domain: <https://internetcomputer.org/docs/current/developer-docs/deploy/custom-domain#creating-the-custom-service-worker>
