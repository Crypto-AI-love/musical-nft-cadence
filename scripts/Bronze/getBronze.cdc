import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Bronze from "../../contracts/Bronze.cdc"

// This script returns an array of all the NFTs in an account's collection.

pub fun main(address: Address): [&Bronze.NFT?] {
    let account = getAccount(address)

    let  collectionRef = account.getCapability(Bronze.BronzeCollectionPublicPath)!.borrow<&{Bronze.BronzeCollectionPublic}>()
        ?? panic("Could not borrow capability from bronzes public collection")

    let bronzeIDs = collectionRef.getIDs()

    var bronzes: [&Bronze.NFT?] = []

    for bronze in bronzeIDs {
        bronzes.append(collectionRef.borrowBronze(id: bronze))
    }

    return bronzes
}