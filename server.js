const express = require("express");
var request = require("request");
var CryptoJS = require("crypto-js");
const { v4: uuidv4 } = require("uuid");

const app = express();
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Successful response from server.js ");
});

const key = "API_KEY_HERE";
const secret = "API_SECERT_HERE";
const url = "URL_ENDPOINT_HERE";

//When ever you communicate with IPG you need to encrypt the body of the message. This function modifies the API call to include the correct message signatures.
function fiservEncode(method, url, body, callback) {
  var ClientRequestId = uuidv4();
  var time = new Date().getTime();
  var requestBody = JSON.stringify(body);
  if (method === "GET") {
    requestBody = "";
  }
  var rawSignature = key + ClientRequestId + time + requestBody;
  var computedHash = CryptoJS.algo.HMAC.create(
    CryptoJS.algo.SHA256,
    secret.toString(),
  );
  computedHash.update(rawSignature);
  computedHash = computedHash.finalize();
  var computedHmac = CryptoJS.enc.Base64.stringify(computedHash);

  var options = {
    method: method,
    url,
    headers: {
      "Content-Type": "application/json",
      "Client-Request-Id": ClientRequestId,
      "Api-Key": key,
      Timestamp: time.toString(),
      "Message-Signature": computedHmac,
    },
    body: JSON.stringify(body),
  };
  callback(options);
}

//Step 2: Create Primary Transaction (Only performs a standard payment that requests 3DSecure!)
app.post("/payments", async (req, res) => {
  //Start by encoding the message.
  fiservEncode(
    "POST",
    url,
    {
      requestType: "PaymentCardSaleTransaction",
      transactionAmount: { total: "13", currency: "GBP" },
      paymentMethod: {
        paymentCard: {
          number: req.body.cardNumber,
          securityCode: req.body.securityCode,
          expiryDate: {
            month: req.body.expiryMonth,
            year: req.body.expiryYear,
          },
        },
      },
    },
    (options) => {
      //Submit the API call to Fiserv
      request(options, function (error, paymentResponse) {
        if (error) throw new Error(error);
        let paymentData = JSON.parse(paymentResponse.body);

        return res.status(200).json({
          requestName: "Payment POST - Creating the payment request",
          ...paymentData,
        });
      });
    },
  );
});

/* app.post("/payments/:transactionId", async (req, res) => { */
/*   const transactionId = req.params.transactionId; */
/*   sdk.auth("YW525BkUF7PyjXymKAGjiBGaBBGgCIwG"); */
/*   sdk.server( */
/*     "https://prod.emea.api.fiservapps.com/sandbox/ipp/payments-gateway/v2", */
/*   ); */
/*   sdk */
/*     .transactionInquiry({ "transaction-id": transactionId }) */
/*     .then(({ data }) => console.log(data)) */
/*     .catch((err) => console.error(err)); */
/* }); */

app.listen(9000, () => console.log("example app is listening on port 9000."));
