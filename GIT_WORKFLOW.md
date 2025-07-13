# Git Workflow for Multi-AI Development - SNS Rooster

## Branching Strategy

### **Main Branches**
```
main                    # Production-ready code
├── develop            # Integration branch for all features
├── feature/backend-*  # Backend AI feature branches
├── feature/frontend-* # Frontend AI feature branches
└── hotfix/*           # Emergency fixes
```

### **Branch Naming Convention**
```
feature/backend/company-models
feature/backend/auth-middleware
feature/frontend/company-context
feature/frontend/auth-ui
hotfix/api-endpoint-fix
```

## AI-Specific Workflow

### **Backend AI Workflow**
```bash
# 1. Start new feature
git checkout develop
git pull origin develop
git checkout -b feature/backend/company-models

# 2. Make changes
# ... implement company models ...

# 3. Commit with conventional format
git add .
git commit -m "feat(backend): add company model with multi-tenant support

- Add Company schema with features and limits
- Update User model with companyId field
- Add company validation middleware
- Update API reference documentation"

# 4. Push and create PR
git push origin feature/backend/company-models
# Create PR to develop branch
```

### **Frontend AI Workflow**
```bash
# 1. Start new feature
git checkout develop
git pull origin develop
git checkout -b feature/frontend/company-context

# 2. Make changes
# ... implement company context provider ...

# 3. Commit with conventional format
git add .
git commit -m "feat(frontend): add company context provider

- Create CompanyProvider for state management
- Add company-aware authentication
- Update API service to include companyId
- Update API reference with usage examples"

# 4. Push and create PR
git push origin feature/frontend/company-context
# Create PR to develop branch
```

## Conventional Commit Format

### **Format**
```
type(scope): description

[optional body]

[optional footer]
```

### **Types**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### **Scopes**
- `backend`: Backend changes
- `frontend`: Frontend changes
- `api`: API contract changes
- `docs`: Documentation changes
- `ci`: CI/CD changes

### **Examples**
```
feat(backend): add company authentication middleware
fix(frontend): resolve company context not updating
docs(api): update user endpoints with company context
refactor(backend): optimize company queries
test(frontend): add company provider tests
```

## Conflict Resolution

### **API Contract Conflicts**
```bash
# When API reference is modified by both AIs
git checkout develop
git pull origin develop

# Backend AI updates API reference
git checkout feature/backend/new-endpoint
git merge develop
# Resolve conflicts in docs/api/API_REFERENCE.md
git add docs/api/API_REFERENCE.md
git commit -m "fix(api): resolve endpoint documentation conflicts"

# Frontend AI updates API reference
git checkout feature/frontend/new-ui
git merge develop
# Resolve conflicts in docs/api/API_REFERENCE.md
git add docs/api/API_REFERENCE.md
git commit -m "fix(api): resolve API usage documentation conflicts"
```

### **Model Conflicts**
```bash
# When database models are modified
git checkout develop
git pull origin develop

# Both AIs must update their models
git checkout feature/backend/updated-models
git merge develop
# Resolve conflicts in models/
git add models/
git commit -m "fix(backend): resolve model conflicts"

git checkout feature/frontend/updated-models
git merge develop
# Resolve conflicts in lib/models/
git add lib/models/
git commit -m "fix(frontend): resolve model conflicts"
```

## Integration Workflow

### **Daily Integration**
```bash
# Morning: Both AIs pull latest changes
git checkout develop
git pull origin develop

# Midday: Quick integration test
git checkout feature/backend/current-feature
git merge develop
# Test integration
git checkout feature/frontend/current-feature
git merge develop
# Test integration

# End of day: Push progress
git push origin feature/backend/current-feature
git push origin feature/frontend/current-feature
```

### **Feature Completion**
```bash
# Backend AI completes feature
git checkout feature/backend/company-auth
git merge develop
# Final testing
git push origin feature/backend/company-auth
# Create PR to develop

# Frontend AI waits for backend PR to merge
git checkout develop
git pull origin develop
git checkout feature/frontend/auth-ui
git merge develop
# Implement UI using merged backend changes
git push origin feature/frontend/auth-ui
# Create PR to develop
```

## Quality Gates

### **Pre-commit Hooks**
```bash
# Backend pre-commit
npm run lint
npm run test
npm run api-docs-check

# Frontend pre-commit
flutter analyze
flutter test
flutter build apk --debug
```

### **PR Requirements**
- [ ] All tests pass
- [ ] Documentation updated
- [ ] API reference updated (if applicable)
- [ ] Code reviewed by other AI
- [ ] Integration tested

## Emergency Procedures

### **Hotfix Workflow**
```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-api-fix

# Fix the issue
# ... make changes ...

# Commit and push
git add .
git commit -m "fix(api): resolve critical authentication issue"
git push origin hotfix/critical-api-fix

# Create PR to main and develop
```

### **Rollback Procedure**
```bash
# If develop branch has issues
git checkout main
git checkout -b hotfix/rollback-develop
git revert <commit-hash>
git push origin hotfix/rollback-develop

# Create PR to main and develop
```

## AI Coordination Commands

### **Check Current Status**
```bash
# Check what branches exist
git branch -a

# Check recent commits
git log --oneline -10

# Check what files changed
git status
git diff --name-only
```

### **Sync with Other AI**
```bash
# Pull latest changes from develop
git checkout develop
git pull origin develop

# Update feature branch
git checkout feature/backend/current-feature
git merge develop

# Check for conflicts
git status
```

## Best Practices

### **For Backend AI**
- Always update API reference when changing endpoints
- Test endpoints before committing
- Use descriptive commit messages
- Create test files for new features

### **For Frontend AI**
- Always check API reference before implementing
- Test UI changes across platforms
- Update API reference with usage examples
- Create test files for new components

### **For Both AIs**
- Commit frequently (at least daily)
- Use conventional commit format
- Update documentation with changes
- Test integration before pushing
- Communicate through commit messages

## Troubleshooting

### **Common Issues**
```bash
# Merge conflicts
git status  # Check conflicted files
git diff    # See conflict markers
# Resolve conflicts manually
git add <resolved-files>
git commit -m "fix: resolve merge conflicts"

# Stuck commits
git log --oneline -5  # Check recent commits
git reset --soft HEAD~1  # Undo last commit
git reset --hard HEAD~1  # Undo last commit and changes

# Lost changes
git reflog  # Find lost commits
git checkout <commit-hash>  # Recover lost work
```

### **Getting Help**
- Check `AI_COORDINATION.md` for coordination issues
- Check `docs/PROJECT_SETUP.md` for setup issues
- Check `SNS-rooster-overall-appFlow.md` for architecture questions
- Use git commands to understand current state 