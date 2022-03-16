//bronzes.test.js
//test bronzes contract on local flow emulator

const config = require("../config.js");
const fjs = require("flow-js-testing/dist");
const path = require("path");

const mintBronze = require('../transactions/Bronze/mintBronze.js');
const getBronze = require('../scripts/Bronze/getBronze.js');
const sendBronze = require('../transactions/Bronze/sendBronze.js');

//init flow-js-testing path
fjs.init(path.resolve(__dirname, "../"));

// mint Bronze
test('Mint Bronze to Sample Account 1', async () => {
    const metadata_1 = [
        { key: "name", value: "NFT 1 Qty 5"},
        { key: "description", value: "Description of NFT"},
        { key: "Author", value: "FirstName LastName"},
        { key: "ipfs", value: "uri_string_identifier0124093485823213"},
        { key: "assetType", value: "video"}
    ]
    await mintBronze(config["0xAdmin"], "Ben", 5, metadata_1);

    const metadata_2 = [
        { key: "name", value: "NFT 2 Qty 3"},
        { key: "description", value: "Description of NFT"},
        { key: "Author", value: "FirstName LastName"},
        { key: "ipfs", value: "uri_string_identifier0124002982344329"},
        { key: "assetType", value: "image"}
    ]
    await mintBronze(config["0xAdmin"], "Sarah", 3, metadata_1);
});

// get Bronze
test('Get Bronze from Sample Accounts', async () => {
    const bronzes = await getBronze("Ben");
    expect(bronzes.length).toBe(5)
    expect(bronzes[0]["metadata"]["name"]).toBe("NFT 1 Qty 5");
    expect(bronzes[3]["serial"]).toBe(4);
    expect(bronzes[3]["serialCount"]).toBe(5);
  });

// send Bronze
test('Send Bronze to/from Sample Accounts', async () => {
    await sendBronze("Ben", "Colin", 2);
    const bronzes = await getBronze("Colin");
    expect(bronzes.length).toBe(1)
    //id indexing starts at 0, serial indexing starts at 1
    expect(bronzes[0]["serial"]).toBe(3);
  });