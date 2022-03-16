const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(sender, recipient, quantity) {
  // Get recipient adresses
  let senderAccount  = {};
  if (sender == config["0xAdmin"]) {
    senderAccount  = sender
  } else {
    senderAccount  = await fjs.getAccountAddress(sender);
  }
  let recipientAccount  = {};
  if (recipient == config["0xAdmin"]) {
    recipientAccount  = recipient
  } else {
    recipientAccount  = await fjs.getAccountAddress(recipient);
  }

  // Read or create transaction code
  const addressMap = {NonFungibleToken: config["0xAdmin"],Bronze: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "Bronze/sendBronze",
    addressMap
  });

  const args = [
    [recipientAccount, t.Address],
    [quantity, t.UInt64]
  ];
  const signers = [senderAccount];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;