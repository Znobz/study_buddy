# Test Case: Assignment Creation Validation

## Test Case ID:
TC-ASSIGNMENT-001

## Test Inputs:

### Valid Assignment Input:
```javascript
{
  title: 'CS Lab 3',
  description: 'Submit circuits report',
  due_date: '2025-11-20',
  priority: 'high',
  status: 'pending'
}
```

### Invalid Assignment Input (Missing Title):
```javascript
{
  description: 'Some description',
  due_date: '2025-11-20'
}
```

### Invalid Assignment Input (Missing Due Date):
```javascript
{
  title: 'Test Assignment',
  description: 'Test description'
}
```

## Expected Results:

1. **Valid Assignment:**
   - `isValid(validAssignment)` should return `true`
   - Both `title` and `due_date` fields should be defined

2. **Invalid Assignment (Missing Title):**
   - `isValid(invalidAssignmentMissingTitle)` should return `false`
   - `title` field should be undefined

3. **Invalid Assignment (Missing Due Date):**
   - `isValid(invalidAssignmentMissingDate)` should return `false`
   - `due_date` field should be undefined

## Dependencies:

- **Testing Framework:** Jest (^29.7.0)
- **Jest Globals:** @jest/globals (^29.7.0)
- **Node.js:** Version that supports ES modules
- **Project Type:** ES Module project (`"type": "module"` in package.json)

## Initialization:

1. Navigate to backend directory: `cd study_buddy_backend`
2. Install dependencies: `npm install --save-dev jest @jest/globals`
3. Ensure `jest.config.js` is configured for ES modules
4. Ensure test script is added to `package.json`:
   ```json
   "test": "node --experimental-vm-modules node_modules/jest/bin/jest.js"
   ```
5. Test file location: `src/controllers/__tests__/assignment.test.js`

## Test Steps:

1. **Step 1:** Define test data
   - Create `validAssignment` object with all required fields
   - Create `invalidAssignmentMissingTitle` object without title
   - Create `invalidAssignmentMissingDate` object without due_date

2. **Step 2:** Verify field existence
   - Assert `validAssignment.title` is defined
   - Assert `validAssignment.due_date` is defined
   - Assert `invalidAssignmentMissingTitle.title` is undefined
   - Assert `invalidAssignmentMissingDate.due_date` is undefined

3. **Step 3:** Define validation function
   - Create `isValid()` function that checks for both `title` and `due_date`

4. **Step 4:** Test validation logic
   - Assert `isValid(validAssignment)` returns `true`
   - Assert `isValid(invalidAssignmentMissingTitle)` returns `false`
   - Assert `isValid(invalidAssignmentMissingDate)` returns `false`

5. **Step 5:** Execute test
   - Run command: `npm test`
   - Verify all assertions pass

## Tear Down:

- No cleanup required for this unit test
- Jest automatically handles test execution and cleanup
- No database connections or external resources to close
- Test data objects are scoped within the test function and automatically garbage collected



