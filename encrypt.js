require("dotenv").config();
const { KMSClient, EncryptCommand } = require("@aws-sdk/client-kms");

async function encrypt(data) {
  const buffer = Buffer.from(data);
  const kms = new KMSClient({
    region: process.env.REGION,
    credentials: {
      accessKeyId: process.env.ACCESS_KEY,
      secretAccessKey: process.env.SECRET_KEY,
    },
  });

  const params = {
    KeyId: "f97f82a9-3b75-4b3a-afd1-3b16b1a953e8",
    Plaintext: buffer,
  };

  try {
    const command = new EncryptCommand(params);
    const data = await kms.send(command);
    return data.CiphertextBlob;
  } catch (err) {
    throw err;
  }
}

module.exports = encrypt;
