# AeMdw - Aeternity Middleware

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [AeMdw - Aeternity Middleware](#aemdw---aeternity-middleware)
    - [Overview](#overview)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Start](#start)
    - [HTTP endpoints](#http-endpoints)
    - [Transaction querying](#transaction-querying)
        - [Scope](#scope)
        - [Query parameters](#query-parameters)
            - [Types](#types)
                - [Supported types](#supported-types)
                - [Supported type groups](#supported-type-groups)
                    - [Examples](#examples)
            - [Generic IDs](#generic-ids)
                - [Supported generic IDs](#supported-generic-ids)
                    - [Examples](#examples-1)
            - [Transaction fields](#transaction-fields)
                - [Supported fields with provided transaction type](#supported-fields-with-provided-transaction-type)
                - [Supported freestanding fields](#supported-freestanding-fields)
                    - [Examples](#examples-2)
            - [Pagination](#pagination)
                - [Examples](#examples-3)
        - [Mixing of query parameters](#mixing-of-query-parameters)
            - [Examples](#examples-4)
    - [Querying from Elixir's shell](#querying-from-elixirs-shell)
        - [MAP function](#map-function)
        - [Arguments](#arguments)
            - [Scope](#scope-1)
            - [Mapper](#mapper)
            - [Query](#query)
            - [Prefer Order](#prefer-order)
        - [Examples](#examples-5)
            - [Continuation example](#continuation-example)
    - [Other transaction related endpoints](#other-transaction-related-endpoints)
        - [TX - get transaction by hash](#tx---get-transaction-by-hash)
        - [TXI - get transaction by index](#txi---get-transaction-by-index)
        - [TXS/COUNT endpoint](#txscount-endpoint)
            - [All transactions](#all-transactions)
            - [Transactions by type/field for ID](#transactions-by-typefield-for-id)
    - [Naming System](#naming-system)
        - [Name Resolution](#name-resolution)
        - [Listing all names](#listing-all-names)
        - [Listing active names](#listing-active-names)
        - [Listing all auctions](#listing-all-auctions)
        - [Showing name pointers](#showing-name-pointers)
        - [Showing name pointees](#showing-name-pointees)
    - [Websocket interface](#websocket-interface)
        - [Message format:](#message-format)
        - [Supported operations:](#supported-operations)
        - [Supported payloads:](#supported-payloads)

<!-- markdown-toc end -->


## Overview

The middleware is a caching and reporting layer which sits in front of the nodes of the [æternity blockchain](https://github.com/aeternity/aeternity). Its purpose is to respond to queries faster than the node can do, and to support queries that for reasons of efficiency the node cannot or will not support itself.

## Prerequisites

Ensure that you have [Elixir](https://elixir-lang.org/install.html) installed, using Erlang 22 or newer.

## Setup

`git clone https://github.com/aeternity/ae_mdw && cd ae_mdw`
  * This project depends on [æternity](https://github.com/aeternity/aeternity) node. It should be then compiled and the path to the node should be configured in `config.exs`, or you can simply export `NODEROOT`. If the variable is not set, by default the path is `../aeternity/_build/local/`.

```
export NODEROOT="path/to/your/node"
```
The NODEROOT directory should contain directories: `bin`, `lib`, `plugins`, `rel` of AE node installation.

## Start

  * Install dependencies with `mix deps.get`
  * Start middleware with `make shell`

## HTTP endpoints

```
GET  /tx/:hash                - returns transaction by hash
GET  /txi/:index              - returns transaction by index (0 .. last transaction index)
GET  /txs/count               - returns total number of transactions (last transaction index + 1)
GET  /txs/count/:id           - returns counts of transactions per transaction field for given id
GET  /txs/:scope_type/:range  - returns transactions bounded by scope/range where query is in query string
GET  /txs/:direction          - returns transactions from beginning (forward) or end (backward), query is in query string
GET  /status                  - returns middleware status (version, number of generations indexed)
```
(more to come)

## Transaction querying

### Scope

Scope specifies the time period to look for transactions matching the criteria, as well as direction:

- forward   - from beginning (genesis) to the end
- backward  - from end (top of chain) to the beginning
- gen/A-B   - from generation A to B (forward if A < B, backward otherwise)
- txi/A-B   - from transaction index A to B (forward if A < B, backward otherwise)

### Query parameters

Querying for transactions via `txs` endpoint supports 3 kinds of parameters specifying which transactions should be part of the reply:

- types
- generic ids
- transaction fields

Pagination supported via specifying of 2 parameters:

- limit
- page

----

#### Types

Types of transactions in the resulting set can be constrained by providing `type` and/or `type_group` parameter.
The query allows providing of multiple type & type_group parameters - they form a union of admissible types.
(In the other words - they are combined with `OR`.)

##### Supported types

* channel_close_mutual, channel_close_solo, channel_create, channel_deposit, channel_force_progress, channel_offchain, channel_settle, channel_slash, channel_snapshot_solo, channel_withdraw
* contract_call, contract_create
* ga_attach, ga_meta
* name_claim, name_preclaim, name_revoke, name_transfer, name_update
* oracle_extend, oracle_query, oracle_register, oracle_response
* paying_for
* spend

##### Supported type groups

Type groups for the transactions listed above are:

* channel
* contract
* ga
* name
* oracle
* paying
* spend

###### Examples

`type` parameter:
```
$ curl -s "http://localhost:4000/txs/forward?type=channel_create&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_2aw4KGSWLq7opXT796a5QZx8Hd7BDaGRSwEcyqzNQMii7MrGrv",
      "block_height": 1208,
      "hash": "th_25ofE3Ah8Fm3PV8oo5Trh5rMMiU4E8uqFfncu9EjJHvubumkij",
      "micro_index": 0,
      "micro_time": 1543584946527,
      "signatures": [
        "sg_2NjzKD4ZKNQiqjAYLVFfVL4ZMCXUhVUEXCmoAZkhAZxsJQmPfzWj3Dq6QnRiXmJDByCPc33qYdwTAaiXDHwpdjFuuxwCT",
        "sg_Wpm8j6ZhRzo6SLnaqWUb24KwFZ7YLws9zHiUKvWrf89cV2RAYGqftXBAzS6Pj7AVWKQLwSjL384yzG7hK4rHB8dn2d67g"
      ],
      "tx": {
        "channel_id": "ch_22usvXSjYaDPdhecyhub7tZnYpHeCEZdscEEyhb2M4rHb58RyD",
        "channel_reserve": 10,
        "delegate_ids": [],
        "fee": 20000,
        "initiator_amount": 50000,
        "initiator_id": "ak_ozzwBYeatmuN818LjDDDwRSiBSvrqt4WU7WvbGsZGVre72LTS",
        "lock_period": 3,
        "nonce": 1,
        "responder_amount": 50000,
        "responder_id": "ak_26xYuZJnxpjuBqkvXQ4EKb4Ludt8w3rGWREvEwm68qdtJLyLwq",
        "state_hash": "st_MHb9b2dXovoWyhDf12kVJPwXNLCWuSzpwPBvMFbNizRJttaZ",
        "type": "ChannelCreateTx",
        "version": 1
      },
      "tx_index": 87
    }
  ],
  "next": "txs/gen/0-265258?limit=1&page=2&type=channel_create"
}
```

`type_group` parameter:
```
$ curl -s "http://localhost:4000/txs/forward?type_group=oracle&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_2G7DgcE1f9QJQNkYnLyTYTq4vjR47G4qUQHkwkXpNiT2J6hm5T",
      "block_height": 4165,
      "hash": "th_iECkSToLNWJ77Fiehi39zxJwLjPfstsAtYFC8rbCsEStEy1xv",
      "micro_index": 0,
      "micro_time": 1544106799973,
      "signatures": [
        "sg_XoYmhU7J6XzJazUvo48ijUKRj5DweV8rBuwBwgdZUiUEeYLe1h4pdJ7jbBWGHC8M7diMA2AFrH1AL739XNChX4wrH58Ng"
      ],
      "tx": {
        "abi_version": 0,
        "account_id": "ak_g5vQK6beY3vsTJHH7KBusesyzq9WMdEYorF8VyvZURXTjLnxT",
        "fee": 20000,
        "nonce": 1,
        "oracle_id": "ok_g5vQK6beY3vsTJHH7KBusesyzq9WMdEYorF8VyvZURXTjLnxT",
        "oracle_ttl": {
          "type": "delta",
          "value": 1234
        },
        "query_fee": 20000,
        "query_format": "the query spec",
        "response_format": "the response spec",
        "type": "OracleRegisterTx",
        "version": 1
      },
      "tx_index": 8891
    }
  ],
  "next": "txs/gen/0-265260?limit=1&page=2&type_group=oracle"
}
```

----

#### Generic IDs

Generic ids allow selecting of transactions related to the provided id in `any` way.

With generic ids, it is possible to select also `create`/`register` transactions of particular Aeternity object (like contract, channel or oracle), despite the fact that these transactions don't have the ID of the created object among its transaction fields.

##### Supported generic IDs

- account
- contract
- channel
- oracle

(todo: name)

###### Examples

```
$ curl -s "http://localhost:4000/txs/forward?contract=ct_2AfnEfCSZCTEkxL5Yoi4Yfq6fF7YapHRaFKDJK3THMXMBspp5z&limit=2" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_ZwPrtCMWMPF5e4RLoaY8cb6HUGadSKknpy5gp8nrDes3eSKyZ",
      "block_height": 218938,
      "hash": "th_6memqAr5S3UQp1pc4FWXT8xUotfdrdUFgBd8VPmjM2ZRuojTF",
      "micro_index": 2,
      "micro_time": 1582898946277,
      "signatures": [
        "sg_LiNE1DtiFkUH19WtJ1p9tX9Zy9fuGaW3bAop1mLCe5jJktQ3XiAu2Bop6JPBrkHyi1eQ2xCyPXQxZmiyqroMwaL7BrqWN"
      ],
      "tx": {
        "abi_version": 3,
        "amount": 0,
        "call_data": "cb_KxFE1kQfK58CoImYHijBOQaROWmeJkniQvuQjKtkbE5UZnXQ+sB9eLb1nwCgkRvEABX1lZmfsIGIeFuXiHMZfg6eGt4RXdqdu+P8EZ1cfiCj",
        "code": "cb_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",
        "contract_id": "ct_2AfnEfCSZCTEkxL5Yoi4Yfq6fF7YapHRaFKDJK3THMXMBspp5z",
        "deposit": 0,
        "fee": 116060000000000,
        "gas": 1000000,
        "gas_price": 1000000000,
        "nonce": 2,
        "owner_id": "ak_26ubrEL8sBqYNp4kvKb1t4Cg7XsCciYq4HdznrvfUkW359gf17",
        "type": "ContractCreateTx",
        "version": 1,
        "vm_version": 5
      },
      "tx_index": 8392766
    },
    {
      "block_hash": "mh_233z34seMczJE7XtGLJN6ZrvJG9eQXG6fdTFymyzYyUyQbt2tY",
      "block_height": 218968,
      "hash": "th_2JLGkWhXbEQxMuEYTxazPurKiwGvo5R6vgqjSBw3R8z9F6b4rv",
      "micro_index": 1,
      "micro_time": 1582904578154,
      "signatures": [
        "sg_HKk9C1vCuHcZRj9zAdh2WvjvwVJwzNkXgPLsqy2SdR3L3hNkc1oMHjNnQxB558mdRWNPP711DMun3KEy9ZYyvo2QgR8B"
      ],
      "tx": {
        "arguments": [
          {
            "type": "string",
            "value": "https://github.com/thepiwo"
          },
          {
            "type": "string",
            "value": "Cool projects!"
          }
        ],
        "function": "tip",
        "result": {
          "type": "unit",
          "value": ""
        },
        "abi_version": 3,
        "amount": 1e+16,
        "call_data": "cb_KxHt0mtGK2lodHRwczovL2dpdGh1Yi5jb20vdGhlcGl3bzlDb29sIHByb2plY3RzIZ01af4=",
        "caller_id": "ak_YCwfWaW5ER6cRsG9Jg4KMyVU59bQkt45WvcnJJctQojCqBeG2",
        "contract_id": "ct_2AfnEfCSZCTEkxL5Yoi4Yfq6fF7YapHRaFKDJK3THMXMBspp5z",
        "fee": 182980000000000,
        "gas": 1579000,
        "gas_price": 1000000000,
        "gas_used": 3600,
        "log": [
          {
            "address": "ct_2AfnEfCSZCTEkxL5Yoi4Yfq6fF7YapHRaFKDJK3THMXMBspp5z",
            "data": "cb_aHR0cHM6Ly9naXRodWIuY29tL3RoZXBpd2+QKOcm",
            "topics": [
              8.317242847728886e+76,
              3.204945213498395e+76,
              1e+16
            ]
          }
        ],
        "nonce": 80,
        "return_type": "ok",
        "type": "ContractCallTx",
        "version": 1
      },
      "tx_index": 8395071
    }
  ],
  "next": "txs/gen/0-265268?contract=ct_2AfnEfCSZCTEkxL5Yoi4Yfq6fF7YapHRaFKDJK3THMXMBspp5z&limit=2&page=2"
}
```

```
$ curl -s "http://localhost:4000/txs/forward?oracle=ok_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_2kSWEwFPPMXSjCx3r1nxi3vnpnXAYB7TEVZuEJsSkGjnsewTBF",
      "block_height": 34421,
      "hash": "th_MRDMpanm3UqgNtAtpEsM59LkyX3TL2wXgeXnx4T9Yn8w1f9L1",
      "micro_index": 0,
      "micro_time": 1549551115213,
      "signatures": [
        "sg_LdVk6F8PPMDPW9ZGkAX653GgaSpjRrfgRByKGAjvxUaBAqjgdG7t6NyLs5UPYBWk7xVEfXgyTNgyrjpvfqaFz7DA9L9ZV"
      ],
      "tx": {
        "abi_version": 0,
        "account_id": "ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR",
        "fee": 20000,
        "nonce": 18442,
        "oracle_id": "ok_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR",
        "oracle_ttl": {
          "type": "delta",
          "value": 1000
        },
        "query_fee": 20000,
        "query_format": "string",
        "response_format": "int",
        "ttl": 50000,
        "type": "OracleRegisterTx",
        "version": 1
      },
      "tx_index": 600284
    }
  ],
  "next": "txs/gen/0-265268?limit=1&oracle=ok_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR&page=2"
}
```

```
$ curl -s "http://localhost:4000/txs/forward?channel=ch_22usvXSjYaDPdhecyhub7tZnYpHeCEZdscEEyhb2M4rHb58RyD&limit=2" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_2aw4KGSWLq7opXT796a5QZx8Hd7BDaGRSwEcyqzNQMii7MrGrv",
      "block_height": 1208,
      "hash": "th_25ofE3Ah8Fm3PV8oo5Trh5rMMiU4E8uqFfncu9EjJHvubumkij",
      "micro_index": 0,
      "micro_time": 1543584946527,
      "signatures": [
        "sg_2NjzKD4ZKNQiqjAYLVFfVL4ZMCXUhVUEXCmoAZkhAZxsJQmPfzWj3Dq6QnRiXmJDByCPc33qYdwTAaiXDHwpdjFuuxwCT",
        "sg_Wpm8j6ZhRzo6SLnaqWUb24KwFZ7YLws9zHiUKvWrf89cV2RAYGqftXBAzS6Pj7AVWKQLwSjL384yzG7hK4rHB8dn2d67g"
      ],
      "tx": {
        "channel_id": "ch_22usvXSjYaDPdhecyhub7tZnYpHeCEZdscEEyhb2M4rHb58RyD",
        "channel_reserve": 10,
        "delegate_ids": [],
        "fee": 20000,
        "initiator_amount": 50000,
        "initiator_id": "ak_ozzwBYeatmuN818LjDDDwRSiBSvrqt4WU7WvbGsZGVre72LTS",
        "lock_period": 3,
        "nonce": 1,
        "responder_amount": 50000,
        "responder_id": "ak_26xYuZJnxpjuBqkvXQ4EKb4Ludt8w3rGWREvEwm68qdtJLyLwq",
        "state_hash": "st_MHb9b2dXovoWyhDf12kVJPwXNLCWuSzpwPBvMFbNizRJttaZ",
        "type": "ChannelCreateTx",
        "version": 1
      },
      "tx_index": 87
    },
    {
      "block_hash": "mh_joVBtAVakCpGWqesP4S8HpDTs6tUuwq2hjpGHwN4aGP1shfFx",
      "block_height": 14258,
      "hash": "th_meBfq6EWuUXExBRkbi618RVkQ8nFMz7uo26HkxFXwko9NjF9L",
      "micro_index": 0,
      "micro_time": 1545910910104,
      "signatures": [
        "sg_GnbScdeBzkXhj9DR1GQcb2LFxHmuL1eNYrScRCPVp2XKt26BoinsrAbdMBWZimqrY36sF5PzAiA4Vqfx6yfGtRtMGXPuQ",
        "sg_VoH1jw5de6wtpzdDsZnA1ATgqV22Rkq2YN2SsphiwqCbY9nipjm3CcwkbKWhAkrud6MnY9biJHVDAzu5UjMf8c691fEcA"
      ],
      "tx": {
        "amount": 10,
        "channel_id": "ch_22usvXSjYaDPdhecyhub7tZnYpHeCEZdscEEyhb2M4rHb58RyD",
        "fee": 17240,
        "nonce": 16,
        "round": 5,
        "state_hash": "st_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACr8s/aY",
        "to_id": "ak_ozzwBYeatmuN818LjDDDwRSiBSvrqt4WU7WvbGsZGVre72LTS",
        "type": "ChannelWithdrawTx",
        "version": 1
      },
      "tx_index": 94616
    }
  ],
  "next": "txs/gen/0-265269?channel=ch_22usvXSjYaDPdhecyhub7tZnYpHeCEZdscEEyhb2M4rHb58RyD&limit=2&page=2"
}
```

----

#### Transaction fields

Every transaction record has one or more fields with identifier, represented by public key.
Middleware is indexing these fields and allows them to be used in the query.

##### Supported fields with provided transaction type

The syntax of the field with provided type is: `type`.`field` - for example: `spend.sender_id`

The fields for transaction types are:

- channel_close_mutual - channel_id, from_id
- channel_close_solo - channel_id, from_id
- channel_create - initiator_id, responder_id
- channel_deposit - channel_id, from_id
- channel_force_progress - channel_id, from_id
- channel_offchain - channel_id
- channel_settle - channel_id, from_id
- channel_slash - channel_id, from_id
- channel_snapshot_solo - channel_id, from_id
- channel_withdraw - channel_id, to_id
- contract_call - caller_id, contract_id
- contract_create - owner_id
- ga_attach - owner_id
- ga_meta - ga_id
- name_claim - account_id
- name_preclaim - account_id, commitment_id
- name_revoke - account_id, name_id
- name_transfer - account_id, name_id, recipient_id
- name_update - account_id, name_id
- oracle_extend - oracle_id
- oracle_query - oracle_id, sender_id
- oracle_register - account_id
- oracle_response - oracle_id
- paying_for - payer_id
- spend - recipient_id, sender_id

##### Supported freestanding fields

In case a freestanding field (without transaction type) is part of the query, it deduces the admissible set of types to those which have this field.

The types for freestanding fields are:

- account_id - name_claim, name_preclaim, name_revoke, name_transfer, name_update, oracle_register
- caller_id - contract_call
- channel_id - channel_close_mutual, channel_close_solo, channel_deposit, channel_force_progress, channel_offchain, channel_settle, channel_slash, channel_snapshot_solo, channel_withdraw
- commitment_id - name_preclaim
- contract_id - contract_call
- from_id - channel_close_mutual, channel_close_solo, channel_deposit, channel_force_progress, channel_settle, channel_slash, channel_snapshot_solo
- ga_id - ga_meta
- initiator_id - channel_create
- name_id - name_revoke, name_transfer, name_update
- oracle_id - oracle_extend, oracle_query, oracle_response
- owner_id - contract_create, ga_attach
- payer_id - paying_for
- recipient_id - name_transfer, spend
- responder_id - channel_create
- sender_id - oracle_query, spend
- to_id - channel_withdraw

###### Examples

with provided transaction type (`name_transfer`):
```
$ curl -s "http://localhost:4000/txs/forward?name_transfer.recipient_id=ak_idkx6m3bgRr7WiKXuB8EBYBoRqVsaSc6qo4dsd23HKgj3qiCF&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_2aLMAszzEf3ZS2Xkn8JRrzU4ogWBzxiDYYFqmUKz1r3XJ7nvEF",
      "block_height": 262368,
      "hash": "th_ssPMQvMPgRgUdbYJXzwxCBugz9J8fgP37MoVdqiBHR71Cm2nM",
      "micro_index": 80,
      "micro_time": 1590759423839,
      "signatures": [
        "sg_DBJnw22QJ7gcfhMMvYdkDqgf3LstHLivZjVdPSXz2LuUHedhQwfrpEEdwvebcqwxdNsrRv7FnzbG8f7oEex3muv7ZayZ5"
      ],
      "tx": {
        "account_id": "ak_QyFYYpgJ1vUGk1Lnk8d79WJEVcAtcfuNHqquuP2ADfxsL6yKx",
        "fee": 17380000000000,
        "name_id": "nm_2t5eU4gLBmMaw4xn3Xb6LZwoJjB5qh6YxT39jKyCq4dvVh8nwf",
        "nonce": 190,
        "recipient_id": "ak_idkx6m3bgRr7WiKXuB8EBYBoRqVsaSc6qo4dsd23HKgj3qiCF",
        "ttl": 262868,
        "type": "NameTransferTx",
        "version": 1
      },
      "tx_index": 11700056
    }
  ],
  "next": "txs/gen/0-265290?limit=1&name_transfer.recipient_id=ak_idkx6m3bgRr7WiKXuB8EBYBoRqVsaSc6qo4dsd23HKgj3qiCF&page=2"
}
```

freestanding field `from_id`, and via `jq` extracting only tx_index and transaction type:
```
curl -s "http://localhost:4000/txs/backward?from_id=ak_ozzwBYeatmuN818LjDDDwRSiBSvrqt4WU7WvbGsZGVre72LTS&limit=5" | jq '.data | .[] | [.tx_index, .tx.type]'
[
  98535,
  "ChannelForceProgressTx"
]
[
  96518,
  "ChannelSettleTx"
]
[
  96514,
  "ChannelSlashTx"
]
[
  94618,
  "ChannelSnapshotSoloTx"
]
[
  94617,
  "ChannelDepositTx"
]
```

----

#### Pagination

Middleware supports 2 optional query parameters:

- limit - limits max number of transactions in the reply (in range 1..1000, default is 10)
- page - tells which page to return (default is 1)

The client can set `limit` explicitly if he wishes to receive different number of transactions in the reply than 10.

The main function of `page` parameter is to support fetching another page from the reply set.
Middleware has DOS protection, by only allowing to ask for subsequent page.
Asking for arbitrary page, without requesting a previous one before results in error:

```
$ curl -s "http://localhost:4000/txs/forward?account=ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR&page=10" | jq '.'
{
  "error": "random access not supported"
}
```

The `txs` endpoint returns json in shape `{"data": [...transactions...], "next": continuation-URL or null}`

The `continuation-URL`, when concatenated with host, can be used to retrieve next page of results.

##### Examples

getting the first transaction:
```
$ curl -s "http://localhost:4000/txs/forward?account=ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_2Rkmk15VeTVWTHt9bVBFcQRuvseKCkuHpm1RexsMcpAdZpFCLx",
      "block_height": 77216,
      "hash": "th_MutYY63TMfYQ7z4rWrQd8WGJqszz1h3FdAGHYLVYJBquHoG2V",
      "micro_index": 0,
      "micro_time": 1557275476873,
      "signatures": [
        "sg_SKC9yVm59qNh3HrpRdqfbkYnoH1ksypECnPxe67iuPadF3KN7HjR4D7qs4gYkeAhbgno2yUjHfZMcTxrF6CKFZQPaGfdq"
      ],
      "tx": {
        "amount": 1e+18,
        "fee": 16840000000000,
        "nonce": 7,
        "payload": "ba_Xfbg4g==",
        "recipient_id": "ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD",
        "sender_id": "ak_2cLJfLQPhkTiz7RCVQ9ii8mVPJu8gHLy6qpafmTcHYrFYWBHCG",
        "type": "SpendTx",
        "version": 1
      },
      "tx_index": 1776073
    }
  ],
  "next": "txs/gen/0-265354?account=ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD&limit=1&page=2"
}
```

getting the next transaction by prepending host (http://localhost:4000) to the continuation-URL from last request:
```
$ curl -s "http://localhost:4000/txs/gen/0-265354?account=ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD&limit=1&page=2" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_SDfdhTd3zfTpAqHMUJsX8RjAm6QyrZYgtqNf3y6EdMMSppEgd",
      "block_height": 77865,
      "hash": "th_2RfB4NrPNyAr8gkm5vTQimVo6uBcZMQfmqdY8LZkuRJfhcs3HA",
      "micro_index": 0,
      "micro_time": 1557391780018,
      "signatures": [
        "sg_XjVTnUbvytX3pAbQQvwYFYXETCqDKzyen7kXqoEqRm5hr6m72k3RzKBHP4GWTHup51ZnxQuDf8R8Rxu5fUwAQGeQMHmh1"
      ],
      "tx": {
        "amount": 1e+18,
        "fee": 16840000000000,
        "nonce": 6,
        "payload": "ba_Xfbg4g==",
        "recipient_id": "ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD",
        "sender_id": "ak_2iK7D3t5xyN8GHxQktvBnfoC3tpq1eVMzTpABQY72FXRfg3HMW",
        "type": "SpendTx",
        "version": 1
      },
      "tx_index": 1779354
    }
  ],
  "next": "txs/gen/0-265354?account=ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD&limit=1&page=3"
}
```

Once there are no more transactions for a query, the `next` key is set to `null`.

----

### Mixing of query parameters

The query string can mix types, global ids and transaction fields.

The resulting set of transactions must meet all constraints specified by parameters denoting ID (global ids and transaction fields) - the parameters are combined with `AND`.

If `type` or `type_group` is provided, the transaction in the result set must be of some type specified by these parameters.

#### Examples

transactions where each transaction contains both accounts, no matter at which field:
```
$ curl -s "http://localhost:4000/txs/backward?account=ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR&account=ak_zUQikTiUMNxfKwuAfQVMPkaxdPsXP8uAxnfn6TkZKZCtmRcUD&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_vCizDmxFrwMFCjBFDWfe8husZ4i8d7K2hFKfmQHhau3DkK9Ka",
      "block_height": 68234,
      "hash": "th_2HvqS7RjoWvBFMGr6WsUsXRhDEcfs3DotZXFm5rRNg7TVZUmnu",
      "micro_index": 0,
      "micro_time": 1555651193447,
      "signatures": [
        "sg_Rimi7QJoHfuFTG79iuZ92GTrmzPcjBxRDe4DniXX9SveAQWcZx9D3FMHUhc7fzfSgJ8vcykGrGpdUXtM3gkFM1pMy4AVL"
      ],
      "tx": {
        "amount": 1,
        "fee": 30000000000000,
        "nonce": 19223,
        "payload": "ba_dGVzdJVNWkk=",
        "recipient_id": "ak_zUQikTiUMNxfKwuAfQVMPkaxdPsXP8uAxnfn6TkZKZCtmRcUD",
        "sender_id": "ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR",
        "ttl": 70000,
        "type": "SpendTx",
        "version": 1
      },
      "tx_index": 1747960
    }
  ],
  "next": "txs/gen/265300-0?account=ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR&account=ak_zUQikTiUMNxfKwuAfQVMPkaxdPsXP8uAxnfn6TkZKZCtmRcUD&limit=1&page=2"
}
```

spend transactions between sender and recipient (transaction type = spend is deduced from the fields):
```
$ curl -s "http://localhost:4000/txs/forward?sender_id=ak_26dopN3U2zgfJG4Ao4J4ZvLTf5mqr7WAgLAq6WxjxuSapZhQg5&recipient_id=ak_r7wvMxmhnJ3cMp75D8DUnxNiAvXs8qcdfbJ1gUWfH8Ufrx2A2&limit=1" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_88NN1Y5rmofQ5SUkQNcuBnLMyQucdrCXXcqBduYjLygDmSuSz",
      "block_height": 172,
      "hash": "th_LnKAy1SDEwQjn9kvVmZ8woCExEX7g29UBvZthWnugKAF2ZBhf",
      "micro_index": 1,
      "micro_time": 1543404316091,
      "signatures": [
        "sg_7wbXjsJLYy3gxGpLsi62s9j7nd4Qm3uppPFsNXLw7WdqZE6b1mPyUqkiMvDTJMD3zQCYy2BNgzpdyLAZJuNmkKKhmFUL3"
      ],
      "tx": {
        "amount": 1000000,
        "fee": 20000,
        "nonce": 10,
        "payload": "ba_SGFucyBkb25hdGVzs/BHFA==",
        "recipient_id": "ak_r7wvMxmhnJ3cMp75D8DUnxNiAvXs8qcdfbJ1gUWfH8Ufrx2A2",
        "sender_id": "ak_26dopN3U2zgfJG4Ao4J4ZvLTf5mqr7WAgLAq6WxjxuSapZhQg5",
        "type": "SpendTx",
        "version": 1
      },
      "tx_index": 9
    }
  ],
  "next": "txs/gen/0-265304?limit=1&page=2&recipient_id=ak_r7wvMxmhnJ3cMp75D8DUnxNiAvXs8qcdfbJ1gUWfH8Ufrx2A2&sender_id=ak_26dopN3U2zgfJG4Ao4J4ZvLTf5mqr7WAgLAq6WxjxuSapZhQg5"
}
```

name related transactions for account:
```
$ curl -s "http://localhost:4000/txs/forward?account=ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD&type_group=name" | jq '.'
{
  "data": [
    {
      "block_hash": "mh_JRADbFAfMf4JJApALLc3JuJgmQtRsQ91WHQvyGZzGJiCuLBFV",
      "block_height": 141695,
      "hash": "th_vNPVyhuUTWkdvU9hTC6vRK52Hevt5Lbv3ZjVV67KoghE1Vake",
      "micro_index": 17,
      "micro_time": 1568931464420,
      "signatures": [
        "sg_C81dBwSTehaPDuz23PDAeZZAgTQYeTGcpYXabkTQiQa7YBzvwwK9us7dxSd6FsqZ2wpzmsM72QYwoUJzKtsY75BG8Eu9i"
      ],
      "tx": {
        "account_id": "ak_AiQGnvEgsbLQixVJABpTc9h7hXtP4Lt3sorCa9FbtvYfiBH6a",
        "fee": 17300000000000,
        "name_id": "nm_2fzt9CmGxe1GgKs42xM95h8nvgXqTECCKqjSZQinQUiwBooGid",
        "nonce": 6,
        "recipient_id": "ak_E64bTuWTVj9Hu5EQSgyTGZp27diFKohTQWw3AYnmgVSWCnfnD",
        "type": "NameTransferTx",
        "version": 1
      },
      "tx_index": 3550045
    }
  ],
  "next": null
}
```

----

## Querying from Elixir's shell

One of the goals of the new middleware was to have the querying ability available in the shell, as a function for easy integration with other parts if needed.

### MAP function

The HTTP request is translated to the call to the query function called `map`, in `AeMdw.Db.Stream` module:

```
map(scope),
map(scope, mapper),
map(scope, mapper, query),
map(scope, mapper, query, prefer_direction),
```

The result of `map` function is a `stream yielding transactions on demand`, not the transctions themselves.

To get the transactions from this stream, it must be consumed with one of:

- `Enum.to_list/1`               - get all transaction
- `Enum.take/2`                  - get chunk of provided size
- `StreamSplit.take_and_drop/2`  - get chunk of provided size AND stream generating the rest of the result set

### Arguments

#### Scope

- `:forward`     - from beginning (genesis) to the end
- `:backward`    - from end (top of chain) to the beginning
- `{:gen, a..b}` - from generation a to b (forward if a < b, backward otherwise)
- `{:txi, a..b}` - from transaction index a to b (forward if a < b, backward otherwise)

#### Mapper

- `:txi`  - extract just transaction index from transactions in result set
- `:raw`  - translate Erlang transaction record into map, enrich the map with additional data, don't encode IDs
- `:json` - translate Erlang transaction record into map, enrich the map with additional data, encode IDs for JSON compatibility

#### Query

Query is a key value list of constraints, as described above:

- `:type`, `:type_group`
- `:account`, `:contract`, `:channel`, `:oracle` (todo: `:name`)
- fields as described above:
  - freestanding: for example: `:sender_id`, `:from_id`, `:contract_id`, ...
  - with type: for example: `:'spend.sender_id'`

As with query string, providing multiple type, or global ids or fields is supported.
Type constraints combine with `OR`, ids and fields combine with `AND`.

#### Prefer Order

Either `:forward` or `:backward`.

This optional parameter is rarely needed.
It's purpose is to force direction of iteration, overriding derived direction from `scope`.

### Examples

For convenience, we alias `AeMdw.Db.Stream` module:
```
alias AeMdw.Db.Stream, as: DBS
```

Binding a stream to a "variable":
```
iex(aeternity@localhost)47> s = DBS.map(:forward, :raw)
#Function<55.119101820/2 in Stream.resource/3>
```

Get first transaction (genesis):
(note that the mapper (when creating the stream) was `:raw` - it affects the format of the output)
```
iex(aeternity@localhost)48> s |> Enum.take(1)
[
  %{
    block_hash: <<119, 150, 138, 100, 62, 23, 145, 61, 204, 61, 156, 228, 43,
      173, 81, 168, 211, 94, 220, 238, 183, 91, 245, 112, 230, 47, 52, 44, 191,
      34, 49, 235>>,
    block_height: 1,
    hash: <<164, 38, 1, 147, 61, 29, 56, 40, 111, 178, 197, 124, 115, 149, 188,
      19, 47, 119, 120, 111, 53, 92, 10, 1, 24, 116, 100, 201, 234, 146, 180,
      157>>,
    micro_index: 0,
    micro_time: 1543375246712,
    signatures: [
      <<112, 133, 201, 51, 75, 65, 83, 138, 79, 82, 251, 174, 141, 218, 143, 44,
        179, 103, 222, 101, 139, 79, 218, 201, 230, 109, 149, 134, 13, 231, 40,
        146, 52, 83, 160, 139, 55, 214, 96, 76, 174, 136, ...>>
    ],
    tx: %{
      amount: 150425,
      fee: 101014,
      nonce: 1,
      payload: "790921-801018",
      recipient_id: {:id, :account,
       <<144, 125, 123, 13, 183, 6, 234, 74, 192, 116, 177, 35, 130, 58, 45,
         133, 185, 14, 29, 143, 113, 100, 77, 100, 127, 133, 98, 225, 46, 110,
         14, 75>>},
      sender_id: {:id, :account,
       <<144, 125, 123, 13, 183, 6, 234, 74, 192, 116, 177, 35, 130, 58, 45,
         133, 185, 14, 29, 143, 113, 100, 77, 100, 127, 133, 98, 225, 46, 110,
         14, 75>>},
      ttl: 0,
      type: :spend_tx
    },
    tx_index: 0
  }
]
```

Get transaction indices (note `txi` mapper) of last 2 transactions of Superhero contract:
```
iex(aeternity@localhost)53> DBS.map(:backward, :txi, contract: "ct_2AfnEfCSZCTEkxL5Yoi4Yfq6fF7YapHRaFKDJK3THMXMBspp5z") |> Enum.take(2)
[11943361, 11942780]
```

Get latest contract creation transaction for account, as JSON compatible map:
```
iex(aeternity@localhost)62> DBS.map(:backward, :json, account: "ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR", type: :contract_create) |> Enum.take(1)
[
  %{
    "block_hash" => "mh_2vf1rUd9eGEK3dErZzVPD3DiAdb2tXgqqCpi5omvvZwPD3KYxh",
    "block_height" => 42860,
    "hash" => "th_2Turq396oFwxMP9R2DGVbhrRx2pcm2TDvwZYHLRxiLkpDzNFt2",
    "micro_index" => 217,
    "micro_time" => 1551072615670,
    "signatures" => ["sg_2XUcjG9Pc5RxrG7pa84LeJsC3nNUEBrJiJAL82GyFKt5pNrGpaPvbyScB7NMssDEpPFTh3fjP3VQMZzxfZdkYExegHmHB"],
    "tx" => %{
      "abi_version" => 1,
      "amount" => 1,
      "call_data" => "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCt9bwh/i9hv+GKi/ANbdv90gR3IIMG58OESu0Pr20OJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAW845bQ==",
      "code" => "cb_+SquRgGgkvoZApwagOEb0ECJTcjFb4LREWQmThWornrMZiqU7IL5F1/4zKAkheOHvLYGQ5t7ogUCl4inPWJBXgCJKqHCyoOZqXs1hYZzeW1ib2y4YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//////////////////////////////////////////7hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAfkB9KAv+IVN5raUdqtpihVQ7AOqCYLAZJbFXpmUWDBtDD6aI410cmFuc2Zlcl9mcm9tuQGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWD//////////////////////////////////////////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAuEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+NKgMo8xCDuRufaoEFAEhHE22v57oLigoUKF/hk+BZ0c6q2MdG90YWxfc3VwcGx5uGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//////////////////////////////////////////+4QAAA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" <> ...,
      "contract_id" => "ct_2aCcWJst7rF6pXd2Sh99QTaqAK2wRa2t1pdsFNn5qVucSfvGmF",
      "deposit" => 4,
      "fee" => 1875780,
      "gas" => 1579000,
      "gas_price" => 1,
      "nonce" => 18558,
      "owner_id" => "ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR",
      "type" => "ContractCreateTx",
      "version" => 1,
      "vm_version" => 1
    },
    "tx_index" => 839835
  }
]
```

#### Continuation example

Gets first `name_transfer` transaction with provided `recipient_id`, and different account in any other field, AND also bind the continuation to variable `cont`:
```
{_, cont} = DBS.map(:forward, :json, 'name_transfer.recipient_id': "ak_idkx6m3bgRr7WiKXuB8EBYBoRqVsaSc6qo4dsd23HKgj3qiCF", account: "ak_25BWMx4An9mmQJNPSwJisiENek3bAGadze31Eetj4K4JJC8VQN") |> StreamSplit.take_and_drop(1)
{[
   %{
     "block_hash" => "mh_L5MkbeEnyJWdxbvQQS3Q2VXe3WVed7phtJPNirGeG3H4W89Tn",
     "block_height" => 263155,
     "hash" => "th_mXbNbgaS8w3wFRd3tHS2mHGVxAnL9jX7SsMN76JqKHHmcrMig",
     "micro_index" => 0,
     "micro_time" => 1590901848030,
     "signatures" => ["sg_8z5HdmBQm5ew51geWDtz3eBXZ1HSc87aPNFJDwEfeKJkBUisMQEQuVMwXpRWCYdbm7sT1DAtLsUAxr6uLPyHmKtou2efH"],
     "tx" => %{
       "account_id" => "ak_25BWMx4An9mmQJNPSwJisiENek3bAGadze31Eetj4K4JJC8VQN",
       "fee" => 17360000000000,
       "name_id" => "nm_2t5eU4gLBmMaw4xn3Xb6LZwoJjB5qh6YxT39jKyCq4dvVh8nwf",
       "nonce" => 1,
       "recipient_id" => "ak_idkx6m3bgRr7WiKXuB8EBYBoRqVsaSc6qo4dsd23HKgj3qiCF",
       "ttl" => 263654,
       "type" => "NameTransferTx",
       "version" => 1
     },
     "tx_index" => 11758274
   }
 ],
 %StreamSplit{
   continuation: #Function<23.119101820/1 in Stream.do_resource/5>,
   stream: #Function<55.119101820/2 in Stream.resource/3>
 }}
```

Get subsequent transaction, using the continuation:
```
iex(aeternity@localhost)69> cont |> Enum.take(1)
[
  %{
    "block_hash" => "mh_wybuH39ALrhL3N1MzRuCC4rA8BmWKtsbVbcVu6aCyzSRrvu8s",
    "block_height" => 263155,
    "hash" => "th_HZgLPr98rabb5fTha2cAmyQiGcREA4DoZpU2VRt8nhXDJDuXe",
    "micro_index" => 2,
    "micro_time" => 1590901854030,
    "signatures" => ["sg_XxqhRsKyr2a4AqdHZESEVf7SoGFAuvSSbaFt6pprh3376FvvztNXKCR2qmGPfT2SFvRsaFgfmujrtbQKPeGgQnGWvF7mJ"],
    "tx" => %{
      "account_id" => "ak_25BWMx4An9mmQJNPSwJisiENek3bAGadze31Eetj4K4JJC8VQN",
      "fee" => 17360000000000,
      "name_id" => "nm_nCeYsPNhTb4TqEdpAWTMaWMpuJQdA9YfTwCPTGRLjo8ETJh2C",
      "nonce" => 2,
      "recipient_id" => "ak_idkx6m3bgRr7WiKXuB8EBYBoRqVsaSc6qo4dsd23HKgj3qiCF",
      "ttl" => 263655,
      "type" => "NameTransferTx",
      "version" => 1
    },
    "tx_index" => 11758279
  }
]
```

The `cont` above could be also passed as parameter to another invocation of `StreamSplit.take_and_drop/2` - producing next result and another continuation.

This design decouples query construction and actual consumption of the result set.

----

## Other transaction related endpoints

### TX - get transaction by hash

```
$ curl -s "http://localhost:4000/tx/th_zATv7B4RHS45GamShnWgjkvcrQfZUWQkZ8gk1RD4m2uWLJKnq" | jq '.'
{
  "block_hash": "mh_2kE3N7GCaeAiowu1a7dopJygxQfxvRXYCNy7Pc657arjCa8PPe",
  "block_height": 257058,
  "hash": "th_zATv7B4RHS45GamShnWgjkvcrQfZUWQkZ8gk1RD4m2uWLJKnq",
  "micro_index": 19,
  "micro_time": 1589801584978,
  "signatures": [
    "sg_Z7bbM2a8tDZchtpAkQuMrw5S3cf3yvVizx5qb6hB58KJBBTqhCcpgq2adwNz9SneSQgzD6QQSToiKn3XosS7qybacLpiG"
  ],
  "tx": {
    "amount": 20000,
    "fee": 19300000000000,
    "nonce": 2129052,
    "payload": "ba_MjU3MDU4OmtoXzhVdnp6am9tZG9ZakdMNURic2hhN1RuMnYzYzNXWWNCVlg4cWFQV0JyZjcyVHhSeWQ6bWhfald1dnhrWTZReXBzb25RZVpwM1B2cHNLaG9ZMkp4cHIzOHhhaWR2aWozeVRGaTF4UDoxNTg5ODAxNTkxQa+0cQ==",
    "recipient_id": "ak_zvU8YQLagjcfng7Tg8yCdiZ1rpiWNp1PBn3vtUs44utSvbJVR",
    "sender_id": "ak_zvU8YQLagjcfng7Tg8yCdiZ1rpiWNp1PBn3vtUs44utSvbJVR",
    "ttl": 257068,
    "type": "SpendTx",
    "version": 1
  },
  "tx_index": 11306257
}
```

### TXI - get transaction by index

```
$ curl -s "http://localhost:4000/txi/10000000" | jq '.'
{
  "block_hash": "mh_2J4A4f7RJ4oVKKCFmBEDMQpqacLZFtJ5oBvx3fUUABmLv5SUZH",
  "block_height": 240064,
  "hash": "th_qYi26SEQoW9baWkwfenWxLCveQ1QNSThEzxxWzfHTscfcfovs",
  "micro_index": 94,
  "micro_time": 1586725056043,
  "signatures": [
    "sg_WomDtVzmhoJ2fitFkHGMEciwgmQ4FqXW1mZ5W9GNFenpsTSSduPA8iswWZnU4xma2g9EzJy8a5EPqtSf1dMZNY1pT7A55"
  ],
  "tx": {
    "amount": 20000,
    "fee": 19340000000000,
    "nonce": 1826406,
    "payload": "ba_MjQwMDY0OmtoXzJ2aFpmRUJSZGpEY2V6Mm5aa3hTU1FHS2tRb0FtQUhrbWhlVU03ZEpFekdBd0pVaVZvOm1oXzJkWEQzVHNqMmU2MUttdFVLRFNLdURrdEVOWXdWZDJjdUhMYUJZTUhKTUZ1RnYydmZpOjE1ODY3MjUwNTYoz+LD",
    "recipient_id": "ak_2QkttUgEyPixKzqXkJ4LX7ugbRjwCDWPBT4p4M2r8brjxUxUYd",
    "sender_id": "ak_2QkttUgEyPixKzqXkJ4LX7ugbRjwCDWPBT4p4M2r8brjxUxUYd",
    "ttl": 240074,
    "type": "SpendTx",
    "version": 1
  },
  "tx_index": 10000000
}
```

### TXS/COUNT endpoint

#### All transactions

```
$ curl -s "http://localhost:4000/txs/count" | jq '.'
11921825
```

#### Transactions by type/field for ID

```
$ curl -s "http://localhost:4000/txs/count/ak_24jcHLTZQfsou7NvomRJ1hKEnjyNqbYSq2Az7DmyrAyUHPq8uR" | jq '.'
{
  "channel_create_tx": {
    "responder_id": 74
  },
  "contract_call_tx": {
    "caller_id": 69
  },
  "contract_create_tx": {
    "owner_id": 3
  },
  "name_claim_tx": {
    "account_id": 7
  },
  "name_preclaim_tx": {
    "account_id": 26
  },
  "name_revoke_tx": {
    "account_id": 1
  },
  "name_transfer_tx": {
    "account_id": 1
  },
  "name_update_tx": {
    "account_id": 40
  },
  "oracle_extend_tx": {
    "oracle_id": 4
  },
  "oracle_query_tx": {
    "oracle_id": 16,
    "sender_id": 556
  },
  "oracle_register_tx": {
    "account_id": 6
  },
  "oracle_response_tx": {
    "oracle_id": 6
  },
  "spend_tx": {
    "recipient_id": 8,
    "sender_id": 18505
  }
}
```

## Naming System

There are several endpoints for querying of the Naming System.

### Name Resolution

```
$ curl -s "http://localhost:4000/name/wwwbeaconoidcom.chain" | jq '.'
{
  "claim_height": 279555,
  "claimant": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
  "claimed": true,
  "expiration_height": 329555,
  "name": "wwwbeaconoidcom.chain",
  "name_id": "nm_MwcgT7ybkVYnKFV6bPqhwYq2mquekhZ2iDNTunJS2Rpz3Njuj",
  "owner": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
  "pointers": {
    "account_pubkey": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C"
  },
  "revoke_height": null
}
```

It's possible to use encoded hash as well:

```
$ curl -s "http://localhost:4000/name/nm_MwcgT7ybkVYnKFV6bPqhwYq2mquekhZ2iDNTunJS2Rpz3Njuj" | jq '.'
{
  "claim_height": 279555,
  "claimant": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
  "claimed": true,
  "expiration_height": 329555,
  "name": "wwwbeaconoidcom.chain",
  "name_id": "nm_MwcgT7ybkVYnKFV6bPqhwYq2mquekhZ2iDNTunJS2Rpz3Njuj",
  "owner": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
  "pointers": {
    "account_pubkey": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C"
  },
  "revoke_height": null
}
```

### Listing all names

The names in reply are ordered by claim height - from newest to oldest.
It’s a paginable endpoint - allows supplying `limit` parameter to specify how many results should be in one reply.

```
$ curl -s "http://localhost:4000/names/all" | jq '.'
{
  "data": [
    {
      "humphreyakanyijukah.chain": {
        "claim_height": 280670,
        "claimant": "ak_2QQr3NMs4TEBEyiZXd2H5z5rEGG9ojR31X7gyu4tuDkiigwKC5",
        "claimed": true,
        "expiration_height": 330670,
        "name_id": "nm_GHnyKjnXb1TPQsBP4ZXvxWCnxVn653ctcZj34RwfgEu4KDyuw",
        "owner": "ak_2QQr3NMs4TEBEyiZXd2H5z5rEGG9ojR31X7gyu4tuDkiigwKC5",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "alaebovictorchima.chain": {
        "claim_height": 280472,
        "claimant": "ak_2j76sWZB4B24HA7HVCnGQVXWzwfTAkfvWvcCKUbx138oADk9Ah",
        "claimed": true,
        "expiration_height": 330472,
        "name_id": "nm_2T1CgLqGJMoZvTaH7xLvsU5myeDaGUsR5Zk4aJjV36oSZK1NrL",
        "owner": "ak_2j76sWZB4B24HA7HVCnGQVXWzwfTAkfvWvcCKUbx138oADk9Ah",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "SamuelTownWriter.chain": {
        "claim_height": 280455,
        "claimant": "ak_2cFmLzmSWsq5FYY2KyMMintYwrfqCHeRi6pbyeAUjFWKA5Dm2v",
        "claimed": true,
        "expiration_height": 330455,
        "name_id": "nm_2TcAfQYFBvtSGZ9sUt7KqBF1v8vvuX777Fv7bSBVnrWhbDuwXS",
        "owner": "ak_2cFmLzmSWsq5FYY2KyMMintYwrfqCHeRi6pbyeAUjFWKA5Dm2v",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "hudie360harmonydeep.chain": {
        "claim_height": 279596,
        "claimant": "ak_hjB43fZej4qzDGs3ptTwM1b1cTNA9Eygpm8ndvqBMHmEKBix4",
        "claimed": true,
        "expiration_height": 329596,
        "name_id": "nm_2N965YVbb8VN28XVhb9jtKaHpm7pd1zTv4a55aJy42zo8zWd1K",
        "owner": "ak_hjB43fZej4qzDGs3ptTwM1b1cTNA9Eygpm8ndvqBMHmEKBix4",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "wwwbeaconoidcom.chain": {
        "claim_height": 279555,
        "claimant": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
        "claimed": true,
        "expiration_height": 329555,
        "name_id": "nm_MwcgT7ybkVYnKFV6bPqhwYq2mquekhZ2iDNTunJS2Rpz3Njuj",
        "owner": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
        "pointers": {
          "account_pubkey": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C"
        },
        "revoke_height": null
      }
    },
    {
      "Djordje.chain": {
        "claim_height": 277609,
        "claimant": "ak_jmofjvvc9qUk2ESVPgHKVbapGVtfPgPfgzwW5QubhJDfEnqVj",
        "claimed": true,
        "expiration_height": 342489,
        "name_id": "nm_8zCxX9VYvh9MNBvcTrfZE3KG5wUuPnRDfDBMXbiZdQW2ndYDU",
        "owner": "ak_jmofjvvc9qUk2ESVPgHKVbapGVtfPgPfgzwW5QubhJDfEnqVj",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "Twitter.chain": {
        "claim_height": 277010,
        "claimant": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
        "claimed": true,
        "expiration_height": 341890,
        "name_id": "nm_2tBQEK9ED871VGhNPek6MyTKP2ZwerUVLjoM5GhTMrVoWnob63",
        "owner": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "OwaenCannomy.chain": {
        "claim_height": 275849,
        "claimant": "ak_ht7LpTUz8UaQH5enwpJgB7CExgGfuCHS8kvryu9Psx5uV95PM",
        "claimed": true,
        "expiration_height": 326329,
        "name_id": "nm_2MJNED2VE8dtM3Mf4imHL7iq3dS8YWPzumKBHsWFUDYK3GJXPi",
        "owner": "ak_ht7LpTUz8UaQH5enwpJgB7CExgGfuCHS8kvryu9Psx5uV95PM",
        "pointers": {
          "account_pubkey": "ak_ht7LpTUz8UaQH5enwpJgB7CExgGfuCHS8kvryu9Psx5uV95PM"
        },
        "revoke_height": null
      }
    },
    {
      "girlwithplanetinpocket.chain": {
        "claim_height": 275769,
        "claimant": "ak_cEjh5on5RvoBw8zqCGS4VWeY2bmNYNPjn3SCZutYyVLWKf7X1",
        "claimed": true,
        "expiration_height": 325769,
        "name_id": "nm_2wVhJtYp9EBqN8LgRFkmQDavoDA2jGDsAybK8FhcZucCHiTdaf",
        "owner": "ak_cEjh5on5RvoBw8zqCGS4VWeY2bmNYNPjn3SCZutYyVLWKf7X1",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "Successoganiru.chain": {
        "claim_height": 275661,
        "claimant": "ak_2A7eB6HoKWUfMKoqNbJqq1zzpWSMxB1RZjTtdhFNjxthxnBaCj",
        "claimed": true,
        "expiration_height": 325661,
        "name_id": "nm_27Gt9NwfpbwFh86oMp3kgJBSx4AqpwzEnknLy3YSbf1fPzCZKK",
        "owner": "ak_2A7eB6HoKWUfMKoqNbJqq1zzpWSMxB1RZjTtdhFNjxthxnBaCj",
        "pointers": {
          "account_pubkey": "ak_2A7eB6HoKWUfMKoqNbJqq1zzpWSMxB1RZjTtdhFNjxthxnBaCj"
        },
        "revoke_height": null
      }
    }
  ],
  "next": "names/all?limit=10&page=2"
}
```

### Listing active names

Similar to endpoint listing all names, but lists only `active` names. Paginable.

```
$ curl -s "http://localhost:4000/names/active" | jq '.'
{
  "data": [
    {
      "humphreyakanyijukah.chain": {
        "claim_height": 280670,
        "claimant": "ak_2QQr3NMs4TEBEyiZXd2H5z5rEGG9ojR31X7gyu4tuDkiigwKC5",
        "claimed": true,
        "expiration_height": 330670,
        "name_id": "nm_GHnyKjnXb1TPQsBP4ZXvxWCnxVn653ctcZj34RwfgEu4KDyuw",
        "owner": "ak_2QQr3NMs4TEBEyiZXd2H5z5rEGG9ojR31X7gyu4tuDkiigwKC5",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "alaebovictorchima.chain": {
        "claim_height": 280472,
        "claimant": "ak_2j76sWZB4B24HA7HVCnGQVXWzwfTAkfvWvcCKUbx138oADk9Ah",
        "claimed": true,
        "expiration_height": 330472,
        "name_id": "nm_2T1CgLqGJMoZvTaH7xLvsU5myeDaGUsR5Zk4aJjV36oSZK1NrL",
        "owner": "ak_2j76sWZB4B24HA7HVCnGQVXWzwfTAkfvWvcCKUbx138oADk9Ah",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "SamuelTownWriter.chain": {
        "claim_height": 280455,
        "claimant": "ak_2cFmLzmSWsq5FYY2KyMMintYwrfqCHeRi6pbyeAUjFWKA5Dm2v",
        "claimed": true,
        "expiration_height": 330455,
        "name_id": "nm_2TcAfQYFBvtSGZ9sUt7KqBF1v8vvuX777Fv7bSBVnrWhbDuwXS",
        "owner": "ak_2cFmLzmSWsq5FYY2KyMMintYwrfqCHeRi6pbyeAUjFWKA5Dm2v",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "hudie360harmonydeep.chain": {
        "claim_height": 279596,
        "claimant": "ak_hjB43fZej4qzDGs3ptTwM1b1cTNA9Eygpm8ndvqBMHmEKBix4",
        "claimed": true,
        "expiration_height": 329596,
        "name_id": "nm_2N965YVbb8VN28XVhb9jtKaHpm7pd1zTv4a55aJy42zo8zWd1K",
        "owner": "ak_hjB43fZej4qzDGs3ptTwM1b1cTNA9Eygpm8ndvqBMHmEKBix4",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "wwwbeaconoidcom.chain": {
        "claim_height": 279555,
        "claimant": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
        "claimed": true,
        "expiration_height": 329555,
        "name_id": "nm_MwcgT7ybkVYnKFV6bPqhwYq2mquekhZ2iDNTunJS2Rpz3Njuj",
        "owner": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
        "pointers": {
          "account_pubkey": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C"
        },
        "revoke_height": null
      }
    },
    {
      "Djordje.chain": {
        "claim_height": 277609,
        "claimant": "ak_jmofjvvc9qUk2ESVPgHKVbapGVtfPgPfgzwW5QubhJDfEnqVj",
        "claimed": true,
        "expiration_height": 342489,
        "name_id": "nm_8zCxX9VYvh9MNBvcTrfZE3KG5wUuPnRDfDBMXbiZdQW2ndYDU",
        "owner": "ak_jmofjvvc9qUk2ESVPgHKVbapGVtfPgPfgzwW5QubhJDfEnqVj",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "Twitter.chain": {
        "claim_height": 277010,
        "claimant": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
        "claimed": true,
        "expiration_height": 341890,
        "name_id": "nm_2tBQEK9ED871VGhNPek6MyTKP2ZwerUVLjoM5GhTMrVoWnob63",
        "owner": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "OwaenCannomy.chain": {
        "claim_height": 275849,
        "claimant": "ak_ht7LpTUz8UaQH5enwpJgB7CExgGfuCHS8kvryu9Psx5uV95PM",
        "claimed": true,
        "expiration_height": 326329,
        "name_id": "nm_2MJNED2VE8dtM3Mf4imHL7iq3dS8YWPzumKBHsWFUDYK3GJXPi",
        "owner": "ak_ht7LpTUz8UaQH5enwpJgB7CExgGfuCHS8kvryu9Psx5uV95PM",
        "pointers": {
          "account_pubkey": "ak_ht7LpTUz8UaQH5enwpJgB7CExgGfuCHS8kvryu9Psx5uV95PM"
        },
        "revoke_height": null
      }
    },
    {
      "girlwithplanetinpocket.chain": {
        "claim_height": 275769,
        "claimant": "ak_cEjh5on5RvoBw8zqCGS4VWeY2bmNYNPjn3SCZutYyVLWKf7X1",
        "claimed": true,
        "expiration_height": 325769,
        "name_id": "nm_2wVhJtYp9EBqN8LgRFkmQDavoDA2jGDsAybK8FhcZucCHiTdaf",
        "owner": "ak_cEjh5on5RvoBw8zqCGS4VWeY2bmNYNPjn3SCZutYyVLWKf7X1",
        "pointers": {},
        "revoke_height": null
      }
    },
    {
      "Successoganiru.chain": {
        "claim_height": 275661,
        "claimant": "ak_2A7eB6HoKWUfMKoqNbJqq1zzpWSMxB1RZjTtdhFNjxthxnBaCj",
        "claimed": true,
        "expiration_height": 325661,
        "name_id": "nm_27Gt9NwfpbwFh86oMp3kgJBSx4AqpwzEnknLy3YSbf1fPzCZKK",
        "owner": "ak_2A7eB6HoKWUfMKoqNbJqq1zzpWSMxB1RZjTtdhFNjxthxnBaCj",
        "pointers": {
          "account_pubkey": "ak_2A7eB6HoKWUfMKoqNbJqq1zzpWSMxB1RZjTtdhFNjxthxnBaCj"
        },
        "revoke_height": null
      }
    }
  ],
  "next": "names/active?limit=10&page=2"
}
```

### Listing all auctions

Lists all auctions, ordered by auction expiration height.
It's a paginable endpoint, as others accepts optional `limit` parameter.
Once a auction in reply set has `“active” : false`, all the remaining auctions are expired as well.

The bids in the auction are name claim transactions which happened in the auction, newest first.

```
$ curl -s "http://localhost:4000/names/auctions" | jq '.'
{
  "data": [
    {
      "ominous.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_2Evf1zwi9YkGLWMBUsXNuj1QaCCXHZr8MtumwkVqSxJqw71GUP",
            "block_height": 266586,
            "hash": "th_gbWe2xpSNtiRZPQ8ju4BYW7zUuqt3kQouwLmbVQzN3UgsLChW",
            "micro_index": 36,
            "micro_time": 1591519266806,
            "signatures": [
              "sg_Ney7PWniDvGNAQnaxnJ1c2mp4zzgciAdRejBEmvGcshnkNaqhcB3NDvj4bovdZmuLyDpgQkYRHJ19d1MDxSSEX49jiaaT"
            ],
            "tx": {
              "account_id": "ak_2vENviBUhrnb3EuvmR2zkQuVwvuBR9Qj3pdQFndiX7xUgLTJPf",
              "fee": 16580000000000,
              "name": "ominous.chain",
              "name_fee": 31781100000000000000,
              "name_id": "nm_YycxoUrtL94JgDM3e9CtmA9guW3DjP6Bi8rLG18eWstJcEwSg",
              "name_salt": 4192979466082651,
              "nonce": 20,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 12012397
          }
        ],
        "expiration_height": 281466,
        "name_id": "nm_YycxoUrtL94JgDM3e9CtmA9guW3DjP6Bi8rLG18eWstJcEwSg"
      }
    },
    {
      "gokhan.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_2bX7jQA3oJfviHTvhm21aT53wN1uP9ttScmWXvpnUQ4VBGNmpk",
            "block_height": 268133,
            "hash": "th_BTPkhxqRQingkMjBodK9RYuQDC55odFwspJjK1CH7Mptz9PDf",
            "micro_index": 0,
            "micro_time": 1591798093272,
            "signatures": [
              "sg_DBHtjcwMR6BsqhJgd9grDDergFHQzStQBf9M7vskTqHPwqHCwDTuSqqwDQPfqEgVaYRwUAWNQVWpkF8gDD3LuZ36eZtMy"
            ],
            "tx": {
              "account_id": "ak_jmofjvvc9qUk2ESVPgHKVbapGVtfPgPfgzwW5QubhJDfEnqVj",
              "fee": 163600000000000,
              "name": "gokhan.chain",
              "name_fee": 51422900000000000000,
              "name_id": "nm_6y59yVycqm31RmeX6EKMN4tDAD9ZonEWNbKQNN3UzHUrxQfLL",
              "name_salt": 1881488702326437,
              "nonce": 2,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 12127131
          }
        ],
        "expiration_height": 283013,
        "name_id": "nm_6y59yVycqm31RmeX6EKMN4tDAD9ZonEWNbKQNN3UzHUrxQfLL"
      }
    },
    {
      "easy.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_2oNnnjqXccCtPkqhzp4iGJDQzmaRwguCVF9cCi14hr8FwQzV9M",
            "block_height": 253281,
            "hash": "th_FMjMjxNX3Dn3rYBwV7Tn5RU3cUQZfAR1JtZNLhonkLhGTzAv3",
            "micro_index": 0,
            "micro_time": 1589116870077,
            "signatures": [
              "sg_84tm6LfMwNzLShz3qKeeonsE3mBu6W5ocd9FACcsLCucQnhMohccTSaBd6S1WU44M6vJt4iWEnXBfTqbYpFc8Gj7Gp8JP"
            ],
            "tx": {
              "account_id": "ak_QyFYYpgJ1vUGk1Lnk8d79WJEVcAtcfuNHqquuP2ADfxsL6yKx",
              "fee": 17080000000000,
              "name": "easy.chain",
              "name_fee": 161552280000000000000,
              "name_id": "nm_FyiZXmrwh7JZXKQnL8KTWrB5FEzjhHghCMgFUUbTRcudEkcTU",
              "name_salt": 9.748484512782775e+76,
              "nonce": 106,
              "ttl": 253780,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11024671
          }
        ],
        "expiration_height": 283041,
        "name_id": "nm_FyiZXmrwh7JZXKQnL8KTWrB5FEzjhHghCMgFUUbTRcudEkcTU"
      }
    },
    {
      "ee.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_xrveFatG93ipP1274oG2Q6gkPhkFaj2TGMPbotdNkxUZ6FosB",
            "block_height": 254060,
            "hash": "th_2SU2b5z2oKpB4nuDPNZynLBL8JpKxqq9BUFDduAzfWXoDZudzF",
            "micro_index": 0,
            "micro_time": 1589257873261,
            "signatures": [
              "sg_CbDMrxWPL5RbBBvpBvsjcQrqQrSz4McATka1tMZiGE9SGUhy5JEZkpGnGqjXQcqjJWb35bkMrR4NVN6HkTFiRtJ6Q8dNo"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "ee.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_QNpJqzfERyGneHMXKTmAXoVcz2Py6xigrJKMUuhhH4USE91R7",
              "name_salt": 6861487644301603,
              "nonce": 623,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11082419
          }
        ],
        "expiration_height": 283820,
        "name_id": "nm_QNpJqzfERyGneHMXKTmAXoVcz2Py6xigrJKMUuhhH4USE91R7"
      }
    },
    {
      "bb.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_BufE6SAU8WdbDAtxiRQZVv7V9mHifTPVnFBVBDLTYah3eoY5c",
            "block_height": 254076,
            "hash": "th_YqJQWC6v9TJToDoKSXu5Gzgw37ZKkeahV6uzzntnVXYufXJjG",
            "micro_index": 0,
            "micro_time": 1589260542649,
            "signatures": [
              "sg_DQfS3CvipxjYa5QqwSxTnsDK45s2M2gC7osoQfVSQ8PXss1CkdRYf43WeaBja7K47mX2qLuy44TdWtPmuTrW5YC34eU8"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "bb.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_2g39jvNhugJV6F49oaAFctinuixBeBThdkwiMcf93UCdBFfSjq",
              "name_salt": 5972095356692947,
              "nonce": 625,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11083490
          }
        ],
        "expiration_height": 283836,
        "name_id": "nm_2g39jvNhugJV6F49oaAFctinuixBeBThdkwiMcf93UCdBFfSjq"
      }
    },
    {
      "dd.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_f3hor7oz1JbpYF7Wqmr2Whsakns3PtYu7wF8SvJGHemHYR7zm",
            "block_height": 254077,
            "hash": "th_2eoLN9SmJp25e7kUhqjzUTFNCkYheZxSvqDgtS4wHBhdwMAu6V",
            "micro_index": 0,
            "micro_time": 1589260605969,
            "signatures": [
              "sg_gvk16JP5i9s3E49PEpsRVMTmEpnXbPptfrjiMpbvUQ6iQTYY1muUYvnSvFPmHDepdoqpaJnN6AwRPazK5w3xbWxu8Aba"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "dd.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_2RwSGBUj7uLtEjYCApywEM687z2tvZ4PfeSjBibdypUjqYGxkj",
              "name_salt": 7957399869698087,
              "nonce": 627,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11083515
          }
        ],
        "expiration_height": 283837,
        "name_id": "nm_2RwSGBUj7uLtEjYCApywEM687z2tvZ4PfeSjBibdypUjqYGxkj"
      }
    },
    {
      "hh.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_FCzmpAqtqWGfw3sSR1Y4mBP1TYB9jocBGWu65ieAcQgAFTQHy",
            "block_height": 254078,
            "hash": "th_8zGfvj2FFcpcrch9rKXmAV7UffJrJLnHrqG8WTinFCP9yEpto",
            "micro_index": 0,
            "micro_time": 1589260681515,
            "signatures": [
              "sg_Fh2aj2u6emzZg8MC9dLrEgGCGgfMYGnLVGvJywMWpPqoCpu5eZCRx6Zc7dAtRHSrntVvtVM3cX18pAfeXp5QD8y42nJdU"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "hh.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_E34SoUvCWRa2gfkS3jGsiM98GTEioSEzkJHxRxbnQVzcF4A8p",
              "name_salt": 4907777260156943,
              "nonce": 629,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11083552
          }
        ],
        "expiration_height": 283838,
        "name_id": "nm_E34SoUvCWRa2gfkS3jGsiM98GTEioSEzkJHxRxbnQVzcF4A8p"
      }
    },
    {
      "ss.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_2f28GjFEKBFJYC5YskqaGS8XRQUrunsRgX2nUTFk6TxLLtyNLy",
            "block_height": 254080,
            "hash": "th_cmFLdTCHRhrkx63gTM4MYko2qspvcn9tit7xWTDeptvadVfzq",
            "micro_index": 0,
            "micro_time": 1589261201505,
            "signatures": [
              "sg_ZBvNiMfDdD9WvtXwxuWUSxrWEwBWroNJEGRKgdGgamX4EkC8ZR4mRNp8LRZPYoVR7ZGbZaSLnKLVnuNwEhqWqE6BR4mV2"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "ss.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_u8zjRsdvWLTs4WCdTjmcfdYXAhnHL1MR62B7SmhrmDfDhf2zz",
              "name_salt": 3203165734438313,
              "nonce": 632,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11083771
          }
        ],
        "expiration_height": 283840,
        "name_id": "nm_u8zjRsdvWLTs4WCdTjmcfdYXAhnHL1MR62B7SmhrmDfDhf2zz"
      }
    },
    {
      "kk.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_FhXGBBrQBkoDe45Qnssy7Kr11z5RoXpDejc7273o9hR9aYL3o",
            "block_height": 254081,
            "hash": "th_JmZNSqKUyG4ZCvX9h6vEfuQCxiiPAPxwFukEqio9WkPzYt3ac",
            "micro_index": 0,
            "micro_time": 1589261854288,
            "signatures": [
              "sg_E243icveeCdTxSE5UpvgWd5nsKSFMunwniUrHxiBJpgb5TP9DKnZqBtWqyHqEwCC7ZeFDfjJ6WxYx2WxwNJBMzNRDYysL"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "kk.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_2txkMuy8JNrtd1HFPPKvqSkXSzuBpgq2nwQTn7TWS2Avn6R88H",
              "name_salt": 5245764596790627,
              "nonce": 635,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11084058
          }
        ],
        "expiration_height": 283841,
        "name_id": "nm_2txkMuy8JNrtd1HFPPKvqSkXSzuBpgq2nwQTn7TWS2Avn6R88H"
      }
    },
    {
      "mm.chain": {
        "active": true,
        "bids": [
          {
            "block_hash": "mh_MwXzbASR6Ng21fy8yaCtqGuih6hXPTG9Lc4tBibLTcrfZ5bre",
            "block_height": 254099,
            "hash": "th_r5vMmo3AzqqCi1oRUxFK14vZ4tjvaHTteQmd3cokU7Fwn74R9",
            "micro_index": 0,
            "micro_time": 1589265279995,
            "signatures": [
              "sg_7eR2h96sU3ihQdk8aMNWUsAdqUykwJ3XUtqNAEaeDGKdzbvvBvnRPmghayFMdfgKAg5c3dnj3jTpusRn4fYy77PufraVT"
            ],
            "tx": {
              "account_id": "ak_iNokaxUWd4RXdUpH4RcTbaEh7DPvzzm5FZ3uQ3ydHWDoY6RbS",
              "fee": 16520000000000,
              "name": "mm.chain",
              "name_fee": 352457800000000000000,
              "name_id": "nm_2KxCt5v8HxSCktCpHvz4ufqaabTthPp6HnSxfmsx9GrYmLgLcS",
              "name_salt": 6354286943105831,
              "nonce": 694,
              "type": "NameClaimTx",
              "version": 2
            },
            "tx_index": 11085505
          }
        ],
        "expiration_height": 283859,
        "name_id": "nm_2KxCt5v8HxSCktCpHvz4ufqaabTthPp6HnSxfmsx9GrYmLgLcS"
      }
    }
  ],
  "next": "names/auctions?limit=10&page=2"
}
```

### Showing name pointers

This is basically a restricted reply from `name/:id` endpoint, returning just pointers.

```
$ curl -s "http://localhost:4000/names/pointers/wwwbeaconoidcom.chain" | jq '.'
{
  "account_pubkey": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C"
}
```

### Showing name pointees

Returns names pointing to a particular pubkey. The reply also has the name update transaction which set up that pointer.

```
$ curl -s "http://localhost:4000/names/pointees/ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C" | jq '.'
{
  "wwwbeaconoidcom.chain": {
    "pointer_key": "account_pubkey",
    "update_tx": {
      "block_hash": "mh_2f9F14PvtVmfqAZnBi5rAsCZinxCK1tmTn1dWQHShJY22KgLBt",
      "block_height": 279558,
      "hash": "th_2rnypSgKfSZWat1t8Cw9Svuhwtm8gQVHggahZ4avi3UKBZwUKd",
      "micro_index": 51,
      "micro_time": 1593862096625,
      "signatures": [
        "sg_4SjeyYWZbLic6QZfiLTY88xED5A1UoYrgUN34bNxQkmqRmeKdRaTC9vC8hr8A8Z8bCzWQD3Z5QxyWHPtEWwV77BkCaHxS"
      ],
      "tx": {
        "account_id": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
        "client_ttl": 84600,
        "fee": 17780000000000,
        "name": "wwwbeaconoidcom.chain",
        "name_id": "nm_MwcgT7ybkVYnKFV6bPqhwYq2mquekhZ2iDNTunJS2Rpz3Njuj",
        "name_ttl": 50000,
        "nonce": 3,
        "pointers": [
          {
            "id": "ak_2HNsyfhFYgByVq8rzn7q4hRbijsa8LP1VN192zZwGm1JRYnB5C",
            "key": "account_pubkey"
          }
        ],
        "type": "NameUpdateTx",
        "version": 1
      },
      "tx_index": 12942695
    }
  }
}
```


## Websocket interface
The websocket interface, which listens by default on port `4001`, gives asynchronous notifications when various events occur.

### Message format:
```
{
"op": "<operation to perform>",
"payload": "<message payload>"
}
```

### Supported operations:
  * Subscribe
  * Unsubscribe

### Supported payloads:
  * KeyBlocks
  * MicroBlocks
  * Transactions
  * Object, which takes a further field, `target` - can be any æternity entity. So you may subscribe to any æternity object type, and be sent all transactions which reference the object. For instance, if you have an oracle `ok_JcUaMCu9FzTwonCZkFE5BXsgxueagub9fVzywuQRDiCogTzse` you may subscribe to this object and be notified of any events which relate to it - presumable you would be interested in queries, to which you would respond. Of course you can also subscribe to accounts, contracts, names, whatever you like.


The websocket interface accepts JSON - encoded commands to subscribe and unsubscribe, and answers these with the list of subscriptions. A session will look like this:

```
wscat -c ws://localhost:4001/websocket

connected (press CTRL+C to quit)
> {"op":"Subscribe", "payload": "KeyBlocks"}
< ["KeyBlocks"]
> {"op":"Subscribe", "payload": "MicroBlocks"}
< ["KeyBlocks","MicroBlocks"]
> {"op":"Unsubscribe", "payload": "MicroBlocks"}
< ["KeyBlocks"]
> {"op":"Subscribe", "payload": "Transactions"}
< ["KeyBlocks","Transactions"]
> {"op":"Unsubscribe", "payload": "Transactions"}
< ["KeyBlocks"]
> {"op":"Subscribe", "payload": "Object", "target":"ak_KHfXhF2J6VBt3sUgFygdbpEkWi6AKBkr9jNKUCHbpwwagzHUs"}
< ["KeyBlocks","ak_KHfXhF2J6VBt3sUgFygdbpEkWi6AKBkr9jNKUCHbpwwagzHUs"]
< {"subscription":"KeyBlocks","payload":{"version":4,"time":1588935852368,"target":505727522,"state_hash":"bs_6PKt6GXM9Nu3As4XYr3kjmMiuJoTzkHUPDAwm21GBtjbpfWyL","prev_key_hash":"kh_2Dtcpq9ZdB7AJK1aeEwQtoSncDhFejSdzgTTwuNyscFzJrnsnJ","prev_hash":"mh_2H9cAZHHbyMzPwd4vjQHZpxXsrggG54VCryh6k1BTk511At8Bs","pow":[895666,52781556,66367943,73040389,83465124,91957344,137512183,139025150,145635838,147496688,174889700,196453040,223464154,236816295,249867489,251365348,253234990,284153380,309504789,316268731,337440038,348735058,352371122,367534696,378716232,396258628,400918205,407082251,424187867,427465210,430070369,430312387,432729464,438115994,440444207,442136189,473766117,478006149,482575574,489211700,498083855,518253098],"nonce":567855076671752,"miner":"ak_2Go59eRMNcdiq5uUvVAKjSRoxtREtJe6QvNdcAAPh9GiE5ekQi","info":"cb_AAACHMKhM24=","height":252274,"hash":"kh_FProa64FL423f3xok2fKTfbsuEP2QtdUM4idN7GidQ279zgZ1","beneficiary":"ak_2kHmiJN1RzQL6zXZVuoTuFaVLTCeH3BKyDMZKmixCV3QSWs3dd"}}
< {"subscription":"Object","payload":{"tx":{"version":1,"type":"SpendTx","ttl":252284,"sender_id":"ak_KHfXhF2J6VBt3sUgFygdbpEkWi6AKBkr9jNKUCHbpwwagzHUs","recipient_id":"ak_KHfXhF2J6VBt3sUgFygdbpEkWi6AKBkr9jNKUCHbpwwagzHUs","payload":"ba_MjUyMjc0OmtoX0ZQcm9hNjRGTDQyM2YzeG9rMmZLVGZic3VFUDJRdGRVTTRpZE43R2lkUTI3OXpnWjE6bWhfMmJTcFlDRVRzZ3hMZDd3eEx2Rkw5Wlp5V1ZqaEtNQXF6aGc3eVB6ZUNraThySFVTbzI6MTU4ODkzNTkwMjSozR4=","nonce":2044360,"fee":19320000000000,"amount":20000},"signatures":["sg_Kdh2uaoaiDEHoehDZsRHk7LvqUm5kPqyKR3RD71utjkkh5DTqoJeNWqYv4gRePL9FyBcU7oeL8nsT39zQg4ydCmiKUuhN"],"hash":"th_rGmoP9FCJMQMJKmwDE8gCk7i63vX33St3UiqGQsRGG1twHD7R","block_height":252274,"block_hash":"mh_2gYb8Pv1yLpdsPjxkzq8g9zzBVy42ZLDRvWH6aKYXhb8QjxdvU"}}
```
Actual chain data is wrapped in a JSON structure identifying the subscription to which it relates.
