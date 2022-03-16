import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Bronze from "../../contracts/Bronze.cdc"

// This transaction configures an account to hold Bronze and SaleOffer items
// Also configures FUSD Vault

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a regular Moment collection
        if signer.borrow<&Bronze.BronzeCollection>(from: Bronze.BronzeCollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- Bronze.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: Bronze.BronzeCollectionStoragePath)

            // create a public capability for the collection
            signer.link<&Bronze.Collection{NonFungibleToken.CollectionPublic, Bronze.BronzeCollectionPublic}>(Bronze.BronzeCollectionPublicPath, target: Bronze.BronzeCollectionStoragePath)
        }

        // If the account is already set up that's not a problem, but we don't want to replace it
        if signer.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
            // Create a new FUSD Vault and put it in storage
            signer.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
            /public/fusdReceiver,
            target: /storage/fusdVault
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&FUSD.Vault{FungibleToken.Balance}>(
            /public/fusdBalance,
            target: /storage/fusdVault
            )
        }
    }
}