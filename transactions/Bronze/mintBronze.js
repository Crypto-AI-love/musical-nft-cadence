const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(auth, recipient, quantity, metadata) {
  // Get adresses
  let authName = {};
  if (auth == config["0xAdmin"]) {
    authName = auth
  } else {
    authName = await fjs.getAccountAddress(auth);
  }
  let recipientName = {};
  if (recipient == config["0xAdmin"]) {
    recipientName = recipient
  } else {
    recipientName = await fjs.getAccountAddress(recipient);
  }

  // Read or create transaction code
  const addressMap = {NonFungibleToken: config["0xAdmin"],Bronze: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "Bronze/mintBronze",
    addressMap
  });

  const args = [
      [recipientName, t.Address],
      [quantity, t.Int],
      [metadata,
        // Since our script expects {String: String} we need to define types for key and value
        t.Dictionary({ key: t.String, value: t.String }),
      ]
  ];

  const signers = [authName];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;