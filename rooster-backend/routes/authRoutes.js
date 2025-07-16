const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const avatarUpload = require("../gcsUpload");
const documentUpload = require('../gcsDocumentUpload');
const authController = require("../controllers/auth-controller");
const { getAvatarSignedUrl } = require("../controllers/avatar-controller");
const router = express.Router();

// Login route
router.post("/login", authController.login);

// Register route (admin only)
router.post("/register", authenticateToken, authController.register);

// Request password reset
// router.post("/reset-password", authController.requestPasswordReset);

// Reset password (token in body)
router.post("/reset-password", authController.resetPassword);

// Email verification routes
router.get("/verify-email", authController.verifyEmail);
router.post("/resend-verification", authController.resendVerificationEmail);

// Get current user profile
router.get("/me", authenticateToken, authController.getCurrentUserProfile);

// Update current user profile
router.patch(
  "/me",
  authenticateToken,
  avatarUpload.single("profilePicture"),
  authController.updateCurrentUserProfile
);
// Upload document (admin and owner only)
router.post(
  "/upload-document",
  authenticateToken,
  documentUpload.single("file"),
  authController.uploadDocument
);

// Debugging route to create a new user (for testing purposes)
router.post("/debug-create-user", authController.debugCreateUser);

// Add route to get all users (admin only)
router.get("/users", authenticateToken, authController.getAllUsers);

// Add route to delete a user by id (admin only)
router.delete("/users/:id", authenticateToken, authController.deleteUser);

// Add route to get user by id (admin only)
router.get('/users/:id/profile', authenticateToken, authController.getUserById);

// Add route to toggle user active status (admin only)
router.patch('/users/:id', authenticateToken, authController.toggleUserActive);

// Forgot password route (notifies admin or sends reset link to admin users)
router.post("/forgot-password", authController.forgotPassword);

// Add route to get signed URL for a user's avatar (owner or admin only)
router.get("/avatar/:userId/signed-url", authenticateToken, getAvatarSignedUrl);

module.exports = router;
