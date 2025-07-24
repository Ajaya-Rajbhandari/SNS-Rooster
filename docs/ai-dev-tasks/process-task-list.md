# Process Task List

## Overview
This document guides the systematic processing of a task list, ensuring methodical implementation with proper review and approval at each step. The goal is to maintain quality control and prevent issues by tackling one task at a time.

## Processing Instructions

### Current Task Focus
When processing a task list, focus on **ONE TASK AT A TIME**. Do not proceed to the next task until the current task is completed and approved.

### Task Processing Steps

1. **Read the Current Task**
   - Review the task description thoroughly
   - Understand the acceptance criteria
   - Identify all files that need to be modified
   - Check dependencies to ensure they're met

2. **Plan the Implementation**
   - Break down the task into smaller steps if needed
   - Identify the specific changes required
   - Consider the impact on existing code
   - Plan testing approach

3. **Implement the Task**
   - Make the necessary code changes
   - Follow coding standards and best practices
   - Include proper error handling
   - Add comments where appropriate

4. **Test the Implementation**
   - Verify the acceptance criteria are met
   - Test edge cases and error conditions
   - Ensure no regressions in existing functionality
   - Validate with the specified testing requirements

5. **Document Changes**
   - Update relevant documentation
   - Add inline comments if needed
   - Update API documentation if applicable
   - Note any configuration changes

6. **Request Review**
   - Present the completed task for review
   - Show the specific changes made
   - Demonstrate that acceptance criteria are met
   - Highlight any issues or concerns

### Review and Approval Process

#### For Each Completed Task:
1. **Show the Task Details**
   - Display the task ID and title
   - Show the acceptance criteria
   - List the files that were modified

2. **Present the Implementation**
   - Show the specific code changes
   - Explain the approach taken
   - Highlight any important decisions made
   - Demonstrate the functionality

3. **Request Approval**
   - Ask for review and feedback
   - Wait for explicit approval before proceeding
   - Address any concerns or requested changes
   - Only mark as complete after approval

#### Approval Responses:
- **"Yes" or "Approve"**: Task is complete, proceed to next task
- **"No" or "Reject"**: Task needs changes, continue working on current task
- **"Modify" or specific feedback**: Make requested changes to current task

### Task Completion Tracking

#### Marking Tasks Complete:
When a task is approved, update the task list to show completion:

```markdown
### Completed Tasks
- [x] Task 1.1: [Task Title] - [Date completed]
- [x] Task 1.2: [Task Title] - [Date completed]

### In Progress
- [ ] Task 2.1: [Task Title] - [Started date]

### Pending
- [ ] Task 3.1: [Task Title]
- [ ] Task 4.1: [Task Title]
```

#### Progress Indicators:
- **Completed**: ✅ [x] Task ID: Task Title - Date
- **In Progress**: 🔄 [ ] Task ID: Task Title - Started Date
- **Pending**: ⏳ [ ] Task ID: Task Title

### Quality Assurance

#### Code Quality Checks:
- Follow established coding standards
- Include proper error handling
- Add appropriate logging
- Ensure security best practices
- Validate input data
- Handle edge cases

#### Testing Requirements:
- Unit tests for new functionality
- Integration tests for API endpoints
- User acceptance testing for UI changes
- Performance testing for critical features
- Security testing for authentication/authorization

#### Documentation Updates:
- Update API documentation
- Add inline code comments
- Update user guides if needed
- Document configuration changes
- Update deployment guides if applicable

### Error Handling and Rollback

#### If Issues Arise:
1. **Identify the Problem**
   - Understand what went wrong
   - Determine the scope of the issue
   - Assess impact on other tasks

2. **Fix the Current Task**
   - Address the specific issue
   - Re-test the implementation
   - Ensure all acceptance criteria are met

3. **Consider Rollback**
   - If the issue is significant, consider rolling back changes
   - Document the issue and solution
   - Plan a different approach if needed

### Communication Guidelines

#### When Presenting a Task:
1. **Be Clear and Concise**
   - Explain what was implemented
   - Show the specific changes made
   - Highlight any important decisions

2. **Provide Context**
   - Explain why certain approaches were chosen
   - Show how the implementation meets requirements
   - Address potential concerns proactively

3. **Ask for Specific Feedback**
   - Request approval or specific changes
   - Ask for clarification if needed
   - Be open to suggestions and improvements

#### When Receiving Feedback:
1. **Listen Carefully**
   - Understand the feedback completely
   - Ask clarifying questions if needed
   - Consider alternative approaches

2. **Implement Changes**
   - Make the requested modifications
   - Re-test the implementation
   - Present the updated solution

3. **Confirm Completion**
   - Ensure all feedback is addressed
   - Verify acceptance criteria are met
   - Get final approval before proceeding

### SNS Rooster Specific Guidelines

#### Multi-tenant Considerations:
- Always test with multiple companies
- Verify company isolation is maintained
- Check subscription plan restrictions
- Validate feature flag behavior

#### Platform Testing:
- Test on Android, iOS, and Web
- Verify responsive design
- Check platform-specific functionality
- Validate cross-platform consistency

#### Security Validation:
- Test authentication and authorization
- Verify data isolation between companies
- Check for security vulnerabilities
- Validate input sanitization

#### Performance Testing:
- Test with realistic data volumes
- Verify response times
- Check database query performance
- Validate scalability

#### Subscription Integration:
- Test feature flag behavior
- Verify usage limit enforcement
- Check upgrade prompts
- Validate plan restrictions

## Example Task Processing

### Starting a Task: 