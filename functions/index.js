const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');
const fetch = require('node-fetch');
const serviceAccount = require('./.serviceAccountKey.json');

admin.initializeApp();

exports.onConsumableCreate = functions.firestore
  .document('users/{uid}/consumables/{purchaseID}')
  .onCreate(async (_, context) => {
    const uid = context.params.uid;
    const userRef = admin.firestore().collection('users').doc(uid);

    try {
      await userRef.update({
        coins: admin.firestore.FieldValue.increment(1),
      });
      console.log(`Incremented coins for user: ${uid}`);
    } catch (error) {
      console.error(`Error incrementing coins for user: ${uid}`, error);
    }
  });

const playDeveloperApi = google.androidpublisher({
  version: 'v3',
  auth: new google.auth.GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  }),
});

async function verifyAndroidSubscription(packageName, subscriptionId, purchaseToken) {
  try {
    const subscription = await playDeveloperApi.purchases.subscriptions.get({
      packageName: packageName,
      subscriptionId: subscriptionId,
      token: purchaseToken,
    });
    return subscription.data;
  } catch (error) {
    console.error('Error verifying Android subscription:', error);
    return null;
  }
}

async function verifyIosSubscription(receiptData) {
  const endpoint = 'https://buy.itunes.apple.com/verifyReceipt';
  const response = await fetch(endpoint, {
    method: 'POST',
    body: JSON.stringify({
      'receipt-data': receiptData,
      'password': process.env.ITUNES_SHARED_SECRET,
    }),
    headers: { 'Content-Type': 'application/json' },
  });

  const responseData = await response.json();
  return responseData;
}

exports.verifyPurchase = functions.https.onRequest(async (req, res) => {
  const { platform, packageName, productID, purchaseToken, receiptData } = req.body;

  let result;
  if (platform === 'android') {
    result = await verifyAndroidSubscription(packageName, productID, purchaseToken);
  } else if (platform === 'ios') {
    result = await verifyIosSubscription(receiptData);
  }

  if (result) {
    res.status(200).send({ valid: true, data: result });
  } else {
    res.status(400).send({ valid: false });
  }
});



