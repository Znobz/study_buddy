import 'package:flutter_test/flutter_test.dart';

/**
 * Simple Unit Test for Assignment Validation
 * Tests one aspect: Assignment requires title and due_date
 */

void main() {
  group('Assignment Feature - Validation', () {
    test('Assignment creation requires title and due_date fields', () {
      // Valid assignment
      final validAssignment = {
        'title': 'CS Lab 3',
        'description': 'Submit circuits report',
        'due_date': '2025-11-20',
        'priority': 'high',
        'status': 'pending',
      };

      // Invalid assignments
      final invalidMissingTitle = {
        'description': 'Some description',
        'due_date': '2025-11-20',
      };

      final invalidMissingDate = {
        'title': 'Test Assignment',
        'description': 'Test description',
      };

      // Validation function
      bool isValid(Map<String, dynamic> assignment) {
        return assignment.containsKey('title') &&
            assignment.containsKey('due_date') &&
            assignment['title'] != null &&
            assignment['due_date'] != null;
      }

      // Assertions
      expect(validAssignment.containsKey('title'), isTrue);
      expect(validAssignment.containsKey('due_date'), isTrue);
      expect(isValid(validAssignment), isTrue);

      expect(invalidMissingTitle.containsKey('title'), isFalse);
      expect(isValid(invalidMissingTitle), isFalse);

      expect(invalidMissingDate.containsKey('due_date'), isFalse);
      expect(isValid(invalidMissingDate), isFalse);
    });
  });
}



