const express = require("express");
const router = express.Router();
const authController = require("../controllers/auth-controller");
const { authenticateToken } = require("../middleware/auth");
const { validateCompanyContext } = require("../middleware/companyContext");
const upload = require("../middleware/upload");

// Login route (no company context needed)
router.post("/login", authController.login);

// Register route (admin only)
router.post("/register", authenticateToken, validateCompanyContext, authController.register);

// Email verification route (no company context needed)
router.get("/verify-email", authController.verifyEmail);

// Forgot password route (no company context needed)
router.post("/forgot-password", authController.forgotPassword);

// Reset password route (no company context needed)
router.post("/reset-password", authController.resetPassword);

// Get current user profile (no company context needed - user can only access their own profile)
router.get("/me", authenticateToken, authController.getCurrentUserProfile);

// Update current user profile (no company context needed - user can only update their own profile)
router.patch("/me", authenticateToken, upload.single("profilePicture"), authController.updateCurrentUserProfile);

// Update user profile by admin (admin only, company-scoped)
router.patch("/users/:id/profile", authenticateToken, validateCompanyContext, upload.single("profilePicture"), authController.updateUserProfileByAdmin);

// Add route to get all users (admin only, company-scoped)
router.get("/users", authenticateToken, validateCompanyContext, authController.getAllUsers);

// Add route to delete a user by id (admin only, company-scoped)
router.delete("/users/:id", authenticateToken, validateCompanyContext, authController.deleteUser);

// Add route to get user by id (admin only, company-scoped)
router.get('/users/:id/profile', authenticateToken, validateCompanyContext, authController.getUserById);

// Add route to toggle user active status (admin only, company-scoped)
router.patch('/users/:id', authenticateToken, validateCompanyContext, authController.toggleUserActive);

// Debug route for creating users (development only)
if (process.env.NODE_ENV === 'development') {
  router.post("/debug-create-user", authController.debugCreateUser);
}

module.exports = router;
