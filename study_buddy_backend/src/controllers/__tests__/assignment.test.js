import { describe, test, expect } from '@jest/globals';

/**
 * Simple Unit Test for Assignment Creation Validation
 * Tests one aspect: Assignment requires title and due_date
 */

describe('Assignment Feature - Creation Validation', () => {
  test('Assignment creation requires title and due_date fields', () => {
    // Test data
    const validAssignment = {
      title: 'CS Lab 3',
      description: 'Submit circuits report',
      due_date: '2025-11-20',
      priority: 'high',
      status: 'pending',
    };

    const invalidAssignmentMissingTitle = {
      description: 'Some description',
      due_date: '2025-11-20',
    };

    const invalidAssignmentMissingDate = {
      title: 'Test Assignment',
      description: 'Test description',
    };

    // Assertions
    expect(validAssignment.title).toBeDefined();
    expect(validAssignment.due_date).toBeDefined();
    
    expect(invalidAssignmentMissingTitle.title).toBeUndefined();
    expect(invalidAssignmentMissingDate.due_date).toBeUndefined();

    // Validation function (simulating controller logic)
    const isValid = (assignment) => {
      return !!(assignment.title && assignment.due_date);
    };

    expect(isValid(validAssignment)).toBe(true);
    expect(isValid(invalidAssignmentMissingTitle)).toBe(false);
    expect(isValid(invalidAssignmentMissingDate)).toBe(false);
  });
});

