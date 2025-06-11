# 🤖 AI Context & Rules – SNS Rooster (for Trae AI)

This file defines the context and coding rules for Trae AI usage in the **SNS Rooster** project.

## 📌 Project Overview

**SNS Rooster** is a full-stack monorepo employee attendance system. It includes:
- Flutter-based frontend apps
- Node.js/Express backend with MongoDB
- Shared packages for reusability
- Future integrations with HR, payroll, and accounting systems

---

## 🧠 Trae AI Usage Rules

### 🚫 Avoid Duplicate Files
- Always **check for existing files** before generating new ones.
- Do **not** create duplicate models, controllers, services, or Dart screens.
- Example: If `employee-model.js` exists, don’t create `EmployeeModel.js` or `employeeModel.js`.

### 📁 Monorepo Folder Structure
sns-rooster/
├── apps/
│ ├── admin_app/ # Flutter app for admins
│ └── employee_app/ # Flutter app for employees
├── packages/
│ ├── shared_ui/ # Reusable Flutter widgets
│ └── api_client/ # Shared API code
├── backend/
│ ├── api/ # Express app: routes, controllers, models
│ ├── services/ # Business logic
│ ├── jobs/ # Background jobs (cron, queues)
│ └── utils/ # Helper functions


---

## 🔤 Naming Conventions

### 🔙 Backend (Node.js/Express)
- Files: `kebab-case` with **domain prefixes**
  - ✅ `auth-controller.js`, `employee-model.js`
- Functions: `camelCase`
- Classes: `PascalCase`

### 📱 Frontend (Flutter)
- Files: `kebab-case`
  - ✅ `login_screen.dart`, `shift_card.dart`
- Classes: `PascalCase`
  - ✅ `LoginScreen`, `ShiftCard`

---

## 🧠 AI Context Comment Headers (Optional in Code)

```js
// AI: SNS Rooster project – check for existing files, follow kebab-case naming, and use domain prefixes.

❌ Examples to Avoid
ShiftScreen.dart + shift_screen.dart → ❌ duplication

authController.js when auth-controller.js exists → ❌ wrong style and duplicate

✅ Examples to Follow
shift_model.dart, clockin_button.dart, employee-service.js, auth-controller.js

🧩 Tips
Place reusable UI in packages/shared_ui/

Place API methods in packages/api_client/

Keep business logic in backend/services/

🧑‍💻 Maintainer Notes
This file helps Trae AI stay consistent and avoid pollution of your codebase. Update it if folder names or rules change.


