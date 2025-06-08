const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createUserDoc = functions.auth.user().onCreate(async (user) => {
  const role = user.email && user.email.toLowerCase().includes("admin") ? "admin" : "employee";
  return admin
    .firestore()
    .collection("users")
    .doc(user.uid)
    .set({
      email: user.email,
      name: user.displayName || "No name",
      role: role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
