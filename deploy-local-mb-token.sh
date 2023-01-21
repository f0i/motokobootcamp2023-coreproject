#!/usr/bin/env bash

set -eu -o pipefail

set -o xtrace

cd ..
echo "checkout icrc1 in $PWD"
echo -n "continue?"
read

#git clone https://github.com/NatLabs/icrc1
cd icrc1
#mops install

#dfx start --background --clean

dfx identity use default

dfx deploy icrc1 --argument '( record {                     
      name = "Local Motoko Bootcamp Token";                         
      symbol = "LMB";                           
      decimals = 6;                                           
      fee = 1;                                        
      max_supply = 1_000_000_000_000_000;                         
      initial_balances = vec {                                
          record {                                            
              record {                                        
                  owner = principal "6xv5m-ks534-xlbgp-km53o-nl3og-elv25-xzxrf-ibew2-xvq4i-qduyn-uae";   
                  subaccount = null;                          
              };                                              
              100_000_000                                 
          }                                                   
      };                                                      
      min_burn_amount = 10_000;                         
      minting_account = null;                                 
      advanced_settings = null;                               
  })'
