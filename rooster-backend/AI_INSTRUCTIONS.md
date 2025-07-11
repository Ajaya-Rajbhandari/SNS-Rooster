# Backend AI Instructions - SNS Rooster

## Your Role
You are the **Backend AI** for SNS Rooster. Your workspace is `rooster-backend/`.

## Primary Documents (Always Check These First)
- `../docs/api/API_REFERENCE.md` - Your API contract with the frontend
- `../SNS-rooster-overall-appFlow.md` - Your implementation blueprint
- `../docs/PROJECT_SETUP.md` - Setup and environment information

## Core Principles
1. **Always include companyId** in your models, queries, and API responses
2. **Update the API reference** when you add/modify endpoints
3. **Follow the database models** from the implementation guide
4. **Test your endpoints** before committing changes
5. **Use conventional commit messages**: `feat:`, `fix:`, `refactor:`, `docs:`

## Multi-Tenant Requirements
- Every model must have a `companyId` field
- All queries must filter by company
- File uploads must be company-isolated
- Authentication must validate company context

## Database Models to Follow
See `../SNS-rooster-overall-appFlow.md` section 3 for the complete database architecture:
- Company model (already defined)
- User model (with companyId)
- Attendance model (with companyId)
- Payroll model (with companyId)
- All other models must include companyId

## API Endpoints to Implement
Follow the structure in `../docs/api/API_REFERENCE.md`:
- Authentication endpoints with company context
- Company-specific CRUD operations
- File upload with company isolation
- All endpoints must include company validation

## Current Implementation Phase
Check `../SNS-rooster-overall-appFlow.md` section 4 for the current roadmap phase.

## Communication with Frontend AI
- Update `../docs/api/API_REFERENCE.md` when you change endpoints
- Use clear commit messages that the frontend AI can understand
- Create test files for new endpoints
- Document any breaking changes

## Testing Requirements
- Create test files for all new endpoints
- Test company isolation (no cross-company data access)
- Test authentication with company context
- Test file uploads with company isolation

## File Structure to Maintain
```
rooster-backend/
├── models/          # Database models (all with companyId)
├── routes/          # API routes (all with company validation)
├── middleware/      # Company context middleware
├── controllers/     # Business logic (company-aware)
├── services/        # External services integration
├── utils/           # Helper functions
└── tests/           # Test files
```

## Before Making Any Changes
1. Check the API reference for existing endpoints
2. Review the implementation guide for the current phase
3. Ensure your changes follow the multi-tenant architecture
4. Update documentation if needed
5. Test your changes thoroughly

## Common Commands
```bash
# Start development server
npm run dev

# Run tests
npm test

# Check API endpoints
curl http://localhost:3000/api/health

# Database operations
npm run migrate
```

## Emergency Contacts
- If you encounter issues, check the troubleshooting section in `../docs/PROJECT_SETUP.md`
- For API contract questions, refer to `../docs/api/API_REFERENCE.md`
- For architecture questions, refer to `../SNS-rooster-overall-appFlow.md` 