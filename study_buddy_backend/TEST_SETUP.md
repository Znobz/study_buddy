# Testing Framework Installation Steps

## Framework Chosen: Jest (for Node.js/JavaScript)

**Why Jest?**
- Jest is the industry-standard testing framework for Node.js/JavaScript projects
- Works seamlessly with Express.js backend
- Built-in assertion library and test runner
- Excellent ES module support

## Installation Steps

### Step 1: Navigate to Backend Directory
```bash
cd study_buddy_backend
```

### Step 2: Install Jest and Required Dependencies
```bash
npm install --save-dev jest @jest/globals
```

This installs:
- `jest` (^29.7.0) - The testing framework
- `@jest/globals` (^29.7.0) - Jest globals for ES module support

### Step 3: Update package.json Scripts
Add the test script to `package.json`:
```json
"scripts": {
  "test": "node --experimental-vm-modules node_modules/jest/bin/jest.js"
}
```

The `--experimental-vm-modules` flag is required because this project uses ES modules (`"type": "module"` in package.json).

### Step 4: Create Jest Configuration File
Create `jest.config.js` in the backend root directory:

```javascript
export default {
  testEnvironment: 'node',
  transform: {},
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  testMatch: ['**/__tests__/**/*.test.js', '**/?(*.)+(spec|test).js'],
};
```

**Configuration Explanation:**
- `testEnvironment: 'node'` - Runs tests in Node.js environment
- `transform: {}` - No transformation needed (using native ES modules)
- `moduleNameMapper` - Maps module paths correctly for ES modules
- `testMatch` - Finds test files in `__tests__` directories or files ending in `.test.js` or `.spec.js`

### Step 5: Verify Installation
Run the test command to verify everything works:
```bash
npm test
```

Expected output should show:
```
PASS  src/controllers/__tests__/assignment.test.js
  Assignment Feature - Creation Validation
    ✓ Assignment creation requires title and due_date fields

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

## Test File Location

The test file is located at:
```
study_buddy_backend/src/controllers/__tests__/assignment.test.js
```

## Running Tests

### Run all tests:
```bash
npm test
```

### Run specific test file:
```bash
npm test assignment.test.js
```

## What Was Tested

**Test Case:** Assignment Creation Validation
- **Aspect Tested:** Assignment requires `title` and `due_date` fields
- **Test File:** `src/controllers/__tests__/assignment.test.js`
- **Test Framework:** Jest (Node.js)

The test validates that:
1. A valid assignment with both `title` and `due_date` passes validation
2. An assignment missing `title` fails validation
3. An assignment missing `due_date` fails validation

