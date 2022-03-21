# File tokens

File tokens is a Polly module for collaborative projects.

### What is a _Polly module_?
Polly is an on-chain framework for deploying your own instances of contracts as proxies. Read more at [polly.tools](https://polly.tools).

### How does it work?
The contract allows the owner to generate mintable batches of ERC721 tokens that enable it's holders to add and update a file reference stored in the token. The metadata contract is seperate and updateable, meaning any given project using the file tokens contract can deploy their own metadata contracts to alter the presentation of the tokens in wallets, aggregators, etc.
