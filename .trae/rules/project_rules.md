# AI Coding Rules – SNS Rooster

## Naming
- Use `kebab-case` for files
- Use domain prefixes for backend files (e.g., `employee-controller.js`)
- Use `PascalCase` for class names
- Use `camelCase` for functions/variables

## File Creation
- 🔒 Check if file already exists before generating new ones
- ❌ Avoid duplicate files or components with different casing
- ✅ Prefer modifying or extending existing code

## Folder Rules
- `shared_ui/`: shared Dart widgets only
- `api_client/`: Dart API request code
- `services/`: backend business logic
- `jobs/`: cron jobs or queue processors
- `utils/`: common backend helpers

## Examples
- ✅ `auth-controller.js`, `shift_screen.dart`, `employee_model.dart`
- ❌ `AuthController.js`, `ShiftScreen.dart`, `employeeModel.js`
