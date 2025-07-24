// Sample function to unlock a user account from Super Admin UI
// Usage: Call unlockUser(userId, superAdminToken) when the unlock button is clicked

export async function unlockUser(userId, superAdminToken) {
  // Use absolute base URL if needed
  const baseUrl = process.env.REACT_APP_API_BASE_URL || 'http://localhost:5000';
  const response = await fetch(`${baseUrl}/api/super-admin/users/${userId}/unlock`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${superAdminToken}`,
      'Content-Type': 'application/json'
    }
  });
  if (!response.ok) {
    // Try to parse error response
    let errorText = await response.text();
    try {
      const errorJson = JSON.parse(errorText);
      throw new Error(errorJson.error || errorJson.message || errorText);
    } catch {
      throw new Error(errorText);
    }
  }
  const result = await response.json();
  return result;
}

// Example usage in your React/Vue/Angular component:
// import { unlockUser } from './api/superAdminUnlockUser';
// ...
// const result = await unlockUser(selectedUserId, superAdminToken);
// if (result.success) alert('User account unlocked!');
// else alert('Failed to unlock account: ' + result.error);
