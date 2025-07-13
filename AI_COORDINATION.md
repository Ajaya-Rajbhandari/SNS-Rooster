# AI Coordination Guide - SNS Rooster

## Overview
This project uses **two AI assistants** working in parallel:
- **Backend AI**: Works in `rooster-backend/` directory
- **Frontend AI**: Works in `sns_rooster/` directory

## Communication Protocol

### 1. **Shared Documentation as Contract**
- `docs/api/API_REFERENCE.md` = API contract between both AIs
- `SNS-rooster-overall-appFlow.md` = Implementation blueprint
- `docs/PROJECT_SETUP.md` = Setup and troubleshooting guide

### 2. **Git as Communication Channel**
- All changes must be committed with clear messages
- Use conventional commit format: `feat(backend):` or `feat(frontend):`
- Create Pull Requests for major features

### 3. **Documentation Updates**
- When Backend AI changes an endpoint → Update `docs/api/API_REFERENCE.md`
- When Frontend AI changes API usage → Update `docs/api/API_REFERENCE.md`
- Both AIs must keep documentation in sync

## Workflow Synchronization

### **Phase-Based Development**
Follow the roadmap in `SNS-rooster-overall-appFlow.md` section 4:

**Phase 1: Foundation (Months 1-2)**
- Backend AI: Database restructuring, company models, middleware
- Frontend AI: Company context, authentication UI
- Both AIs: Integration testing

**Phase 2: Super Admin System (Months 3-4)**
- Backend AI: Super admin endpoints, feature management
- Frontend AI: Super admin dashboard, feature toggles
- Both AIs: Admin functionality testing

**Phase 3: Billing & Subscription (Months 5-6)**
- Backend AI: Subscription models, payment integration
- Frontend AI: Billing UI, subscription management
- Both AIs: Payment flow testing

**Phase 4: Advanced Features (Months 7-8)**
- Backend AI: Customization APIs, advanced analytics
- Frontend AI: Custom UI, advanced dashboards
- Both AIs: Final integration and testing

### **Daily Sync Points**
1. **Morning**: Both AIs review latest commits and documentation
2. **Midday**: Quick status check on implementation progress
3. **End of day**: Update documentation with any changes

## Conflict Resolution

### **API Contract Conflicts**
- `docs/api/API_REFERENCE.md` is the **single source of truth**
- If Backend AI changes an endpoint → Must update API reference
- If Frontend AI needs different API → Must request through documentation

### **Model Conflicts**
- Database models in `SNS-rooster-overall-appFlow.md` are the blueprint
- Both AIs must follow the same model structure
- Changes require documentation updates

### **Feature Dependencies**
- Backend AI works on core features first
- Frontend AI waits for backend completion
- Use the roadmap for proper sequencing

## Quality Assurance

### **Testing Requirements**
- Backend AI: Create test files for all endpoints
- Frontend AI: Create test files for all components
- Both AIs: Test integration points

### **Code Review Process**
- Backend AI reviews frontend API integration
- Frontend AI reviews backend endpoint usability
- Both AIs ensure documentation accuracy

## Emergency Procedures

### **If Documentation is Out of Sync**
1. Check `docs/api/API_REFERENCE.md` for latest API contract
2. Update any outdated references
3. Commit documentation fixes immediately

### **If Integration Fails**
1. Check API reference for endpoint changes
2. Verify company context is properly included
3. Test with provided test scripts
4. Update documentation if needed

### **If AI Gets Confused**
1. Refer to `AI_INSTRUCTIONS.md` in respective directories
2. Check the implementation guide for current phase
3. Review recent commits for context
4. Ask for clarification through documentation updates

## Success Metrics

- **Zero API mismatches** between frontend and backend
- **Consistent documentation** that both AIs follow
- **Working integration** at each checkpoint
- **Clear commit history** showing collaboration
- **Complete feature implementation** according to roadmap

## File Structure for AI Coordination

```
SNS-Rooster/
├── AI_COORDINATION.md              # This file
├── SNS-rooster-overall-appFlow.md  # Implementation blueprint
├── docs/
│   ├── api/API_REFERENCE.md        # API contract
│   └── PROJECT_SETUP.md            # Setup guide
├── rooster-backend/
│   └── AI_INSTRUCTIONS.md          # Backend AI instructions
└── sns_rooster/
    └── AI_INSTRUCTIONS.md          # Frontend AI instructions
```

## Getting Started

1. **Backend AI**: Read `rooster-backend/AI_INSTRUCTIONS.md`
2. **Frontend AI**: Read `sns_rooster/AI_INSTRUCTIONS.md`
3. **Both AIs**: Review `SNS-rooster-overall-appFlow.md` for current phase
4. **Both AIs**: Check `docs/api/API_REFERENCE.md` for API contract
5. **Begin implementation** according to the roadmap

## Remember
- **Documentation is your contract**
- **Git commits are your communication**
- **Testing is your validation**
- **The roadmap is your guide** 