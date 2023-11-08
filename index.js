/* const express = require("express"); */
/* var request = require("request"); */
/* var CryptoJS = require("crypto-js"); */
/* const { v4: uuidv4 } = require("uuid"); */
/**/
/* const app = express(); */
/* app.use(express.json()); */
/**/
/* app.get("/", (req, res) => { */
/*   res.send("Successful response."); */
/* }); */
/**/
/* function fiservEncode(method, url, body, callback) { */
/*   var ClientRequestId = uuidv4(); */
/*   var time = new Date().getTime(); */
/*   var requestBody = JSON.stringify(body); */
/*   if (method === "GET") { */
/*     requestBody = ""; */
/*   } */
/*   var rawSignature = key + ClientRequestId + time + requestBody; */
/*   var computedHash = CryptoJS.algo.HMAC.create( */
/*     CryptoJS.algo.SHA256, */
/*     secret.toString(), */
/*   ); */
/*   computedHash.update(rawSignature); */
/*   computedHash = computedHash.finalize(); */
/*   var computedHmac = CryptoJS.enc.Base64.stringify(computedHash); */
/**/
/*   var options = { */
/*     method: method, */
/*     url, */
/*     headers: { */
/*       "Content-Type": "application/json", */
/*       "Client-Request-Id": ClientRequestId, */
/*       "Api-Key": key, */
/*       Timestamp: time.toString(), */
/*       "Auth-Token-Type": "HMAC", */
/*       Authorization: computedHmac, */
/*     }, */
/*     body: JSON.stringify(body), */
/*   }; */
/**/
/*   callback(options); */
/* } */
/**/
/* app.post("/charges", async (req, res) => { */
/*   fiservEncode( */
/*     "POST", */
/*     urlCharge, */
/*     { */
/*       amount: { */
/*         total: req.body.amount.total, */
/*         currency: req.body.amount.currency, */
/*       }, */
/*       source: { */
/*         sourceType: req.body.source.sourceType, */
/*         card: { */
/*           cardData: req.body.source.card.cardData, */
/*           expirationMonth: req.body.source.card.expirationMonth, */
/*           expirationYear: req.body.source.card.expirationYear, */
/*           securityCode: req.body.source.card.securityCode, */
/*         }, */
/*       }, */
/*       transactionDetails: { */
/*         captureFlag: true, */
/*       }, */
/*       merchantDetails: { */
/*         merchantId: "100008000003683", */
/*         terminalId: "10000001", */
/*       }, */
/*     }, */
/*     (options) => { */
/*       request(options, function (error, paymentResponse) { */
/*         if (error) throw new Error(error); */
/*         let paymentData = JSON.parse(paymentResponse.body); */
/**/
/*         return res.status(201).json({ */
/*           requestName: "Charge POST - Charge transaction", */
/*           ...paymentData, */
/*         }); */
/*       }); */
/*     }, */
/*   ); */
/* }); */
/**/
/* app.post("/inquiry", async (req, res) => { */
/*   fiservEncode( */
/*     "POST", */
/*     urlInquiry, */
/*     { */
/*       referenceTransactionDetails: { */
/*         referenceTransactionId: */
/*           req.body.referenceTransactionDetails.referenceTransactionId, */
/*       }, */
/*       merchantDetails: { */
/*         merchantId: "100008000003683", */
/*       }, */
/*     }, */
/*     (options) => { */
/*       request(options, function (error, paymentResponse) { */
/*         if (error) throw new Error(error); */
/*         let paymentData = JSON.parse(paymentResponse.body); */
/**/
/*         return res.status(201).json({ */
/*           requestName: "Charge POST - transaction inquiry", */
/*           ...paymentData, */
/*         }); */
/*       }); */
/*     }, */
/*   ); */
/* }); */
/**/
/* app.listen(9000, () => console.log("example app is listening on port 9000.")); */
