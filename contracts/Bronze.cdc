import NonFungibleToken from "./NonFungibleToken.cdc"

// Bronze
// Bronze NFTs for Creators
// Metadata should contain a IPFS link to off-chain content, etc. picture/video
//
pub contract Bronze: NonFungibleToken {

    // Events
    //
    pub event BronzeContractInitialized()
    pub event BronzeWithdraw(id: UInt64 from: Address?)
    pub event BronzeDeposit(id: UInt64 to: Address?)
    pub event BronzeMinted(id: UInt64)

    // Named Paths
    //
    pub let BronzeCollectionStoragePath: StoragePath
    pub let BronzeCollectionPublicPath: PublicPath
    pub let BronzeMinterStoragePath: StoragePath

    // totalSupply
    // The total number of Bronze that have been minted
    //
    pub var totalSupply: UInt64
    pub var totalBronzeIDs: UInt64

    // NFT
    // A Bronze as an NFT
    //
    pub resource BronzeNFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        // The token's bronzeID to identify the bronze (multiple NFTs with different serial numbers reference the same bronze)
        pub let bronzeid: UInt64
        // The token's serial number (multiple minting)
        pub let serial: Int
        // The total quantity of serial numbers (multiple minting)
        pub let serialCount: Int
        // The token's metadata as a string  mapping
        // Can be changed (var)
        pub var metadata: {String : String}

        // initializer
        //
        init(initID: UInt64, initbronzeID: UInt64, initSerial: Int, totalSerials: Int, initMetadata: {String : String}) {
            self.id = initID
            self.bronzeid = initbronzeID
            self.serial = initSerial
            self.serialCount = totalSerials
            self.metadata = initMetadata
        }
    }

    // This is the interface that users can cast their Bronze Collection as
    // to allow others to deposit Bronze into their Collection. It also allows for reading
    // the details of Bronze in the Collection.
    pub resource interface BronzeCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBronze(id: UInt64): &Bronze.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Bronze reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Bronze NFTs owned by an account
    //
    pub resource BronzeCollection: BronzeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        // metadataObjs is a dictionary of metadata mapped to NFT IDs
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit BronzeWithdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Bronze.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit BronzeDeposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowBronze
        // Gets a reference to an NFT in the collection as a Bronze,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the Bronze.
        //
        pub fun borrowBronze(id: UInt64): &Bronze.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Bronze.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create BronzeCollection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource BronzeNFTMinter {

        // mintNFTs
        // Mints multiple new NFTs with the same bronzeid
        // Increments serial number
        // deposits all in the recipients collection using their collection reference
        //
        pub fun mintNFTs(recipient: &{NonFungibleToken.CollectionPublic}, serialQuantity: Int, metadata: {String : String}) {

            var serialNumber = 1

            while serialNumber <= serialQuantity {
                emit BronzeMinted(id: Bronze.totalSupply)

                // deposit it in the recipient's account using their reference
                recipient.deposit(token: <-create Bronze.NFT(initID: Bronze.totalSupply, initbronzeID: Bronze.totalBronzeIDs, initSerial: serialNumber, totalSerials: serialQuantity, initMetadata: metadata))

                serialNumber = serialNumber + 1

                Bronze.totalSupply = Bronze.totalSupply + (1 as UInt64)
            }

            Bronze.totalBronzeIDs = Bronze.totalBronzeIDs + (1 as UInt64)
        }
    }

    // fetch
    // Get a reference to a Bronze from an account's Collection, if available.
    // If an account does not have a Bronze.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Bronze.NFT? {
        let collection = getAccount(from)
            .getCapability(Bronze.CollectionPublicPath)
            .borrow<&Bronze.Collection{Bronze.BronzeCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust Bronze.Collection.borrowBronze to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowBronze(id: itemID)
    }

    // initializer
    //
    init() {
        // Set our named paths
        self.BronzeCollectionStoragePath = /storage/Bronze_Collection
        self.BronzeCollectionPublicPath = /public/Bronze_Collection
        self.BronzeMinterStoragePath = /storage/Bronze_Minter

        // Initialize the total supply
        self.totalSupply = 0

        // Initialize the Bronze IDs
        self.totalBronzeIDs = 0

        // Create a Minter resource and save it to storage
        let minter <- create BronzeNFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit BronzeContractInitialized()
    }
}
