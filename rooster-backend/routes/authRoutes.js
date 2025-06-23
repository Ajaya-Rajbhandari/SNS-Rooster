const express = require("express");
const auth = require("../middleware/auth");
const upload = require("../middleware/upload");
const authController = require("../controllers/auth-controller");
const router = express.Router();

// Login route
router.post("/login", authController.login);

// Register route (admin only)
router.post("/register", auth, authController.register);

// Request password reset
router.post("/reset-password", authController.requestPasswordReset);

// Reset password with token
router.post("/reset-password/:token", authController.resetPassword);

// Get current user profile
router.get("/me", auth, authController.getCurrentUserProfile);

// Update current user profile
router.patch(
  "/me",
  auth,
  upload.single("profilePicture"),
  authController.updateCurrentUserProfile
);
// Upload document (admin and owner only)
router.post(
  "/upload-document",
  auth,
  upload.single("file"),
  authController.uploadDocument
);

// Debugging route to create a new user (for testing purposes)
router.post("/debug-create-user", authController.debugCreateUser);

module.exports = router;
