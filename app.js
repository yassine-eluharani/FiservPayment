const express = require("express");
const bodyParser = require("body-parser");
var request = require("request");
var CryptoJS = require("crypto-js");
const { v4: uuidv4 } = require("uuid");
require("dotenv").config();
const db = require("./db.js");
const encrypt = require("./encrypt");

const app = express();
const port = 8080;

app.use(bodyParser.json());

db.connectToDatabase();

const key = process.env.KEY;
const secret = process.env.SECRET;
const url = process.env.URL;

app.get("/health", (req, res) => {
  res.header({ "System-Health": true });
  res.sendStatus(204);
});

app.get("/", (req, res) => {
  res.send("Successful response from webserver 2");
});

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

app.post("/payments", async (req, res) => {
  fiservEncode(
    "POST",
    url,
    {
      requestType: "PaymentCardSaleTransaction",
      transactionAmount: { total: req.body.total, currency: req.body.currency },
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
      request(options, async function (error, paymentResponse) {
        if (error) throw new Error(error);
        let paymentData = JSON.parse(paymentResponse.body);

        const {
          clientRequestId,
          apiTraceId,
          ipgTransactionId,
          orderId,
          transactionType,
          country,
          terminalId,
          merchantId,
          transactionTime,
          approvedAmount,
          transactionAmount,
          transactionStatus,
          approvalCode,
          schemeTransactionId,
          processor: { referenceNumber, authorizationCode },
        } = paymentData;
        const { cardNumber, expiryMonth, expiryYear } = req.body;
        const encryptedCardNumber = await encrypt(cardNumber);

        const insertObject = {
          clientRequestId,
          apiTraceId,
          ipgTransactionId,
          orderId,
          transactionType,
          paymentMethodBrand:
            paymentData.paymentMethodDetails.paymentMethodBrand,
          paymentMethodType: paymentData.paymentMethodDetails.paymentMethodType,
          country,
          terminalId,
          merchantId,
          transactionTime,
          approvedAmountTotal: approvedAmount.total,
          approvedAmountCurrency: approvedAmount.currency,
          transactionAmountTotal: transactionAmount.total,
          transactionAmountCurrency: transactionAmount.currency,
          transactionStatus,
          approvalCode,
          schemeTransactionId,
          referenceNumber,
          authorizationCode,
          cardNumber: encryptedCardNumber,
          expiryMonth,
          expiryYear,
        };
        try {
          const insertQuery = "INSERT INTO payments SET ?";
          await db.connection.query(insertQuery, insertObject);

          return res.status(200).json({
            requestName: "Payment POST - Creating the payment request",
            ...paymentData,
          });
        } catch (err) {
          console.error("Error inserting data into database:", err);
          return res.status(500).json({ error: "Internal server error" });
        }
      });
    },
  );
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});
