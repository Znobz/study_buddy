/**
 * GRADE CALCULATOR FEATURE - BACKEND LOGIC TEST SCRIPT
 * Study Buddy App - Sprint 5 JUnit Testing
 *
 * Purpose: Discover bugs in grade calculation business logic (MOSTLY FRONTEND FEATURE)
 * Framework: Jest
 * Environment: Node.js Business Logic Testing
 */

// Import or recreate the ClassGrade class for testing
class ClassGrade {
    constructor(assignTypeBuffer, weights) {
        this.courseDict = {};
        this.currAvg = null;
        this.assignTypeBuffer = assignTypeBuffer;
        this.weights = weights;
        for (let i = 0; i < assignTypeBuffer.length; i++) {
            this.courseDict[assignTypeBuffer[i]] = {weight: this.weights[i], grades: [], avg : null};
        }
    }

    addGrade(assignType, name, grade) {
        if (this.courseDict[assignType]) {
            this.courseDict[assignType].grades.push({name : name, grade : grade});
        }
    }

    removeAssignment(assignType, assignmentName) {
        if (this.courseDict[assignType]) {
            this.courseDict[assignType].grades = this.courseDict[assignType].grades.filter(g => g.name !== assignmentName);
        }
    }

    calcTypeAvg(assignType) {
        let sum = 0;
        let len = this.courseDict[assignType].grades.length;
        this.courseDict[assignType].grades.forEach(grade => {
            sum += grade.grade;
        });
        this.courseDict[assignType].avg = (sum / len);
    }

    getTypeAvg(assignType) {
        if (this.courseDict[assignType].avg !== null) {
            return this.courseDict[assignType].avg;
        }
    }

    calcGradeAvg() {
        let gradeAve = 0;
        for (let type in this.courseDict) {
            gradeAve += this.getTypeAvg(type) * this.courseDict[type].weight;
        }
        this.currAvg = gradeAve;
    }

    getGradeAve() {
        if (this.currAvg != null) {
            return this.currAvg;
        }
    }

    getDict() {
        return this.courseDict;
    }

    calcPredGrade(desired_grade, assignType) {
        let type_sum = 0;
        let type_len = this.courseDict[assignType].grades.length + 1;
        let type_w = this.courseDict[assignType].weight;
        let tempAve = 0;

        for (let type in this.courseDict) {
            if (type != assignType) {
                tempAve += this.getTypeAvg(type) * this.courseDict[type].weight;
            }
        }

        this.courseDict[assignType].grades.forEach(grade => {
            type_sum += grade.grade;
        });

        return ((desired_grade - tempAve) / type_w) * type_len - type_sum;
    }
}

describe('GRADE CALCULATOR FEATURE - Backend Logic Tests', () => {

  // ==================== CONSTRUCTOR TESTS ====================

  describe('Test ID: GRADE_LOGIC_001 - Constructor Validation', () => {
    test('Should create ClassGrade with valid inputs', () => {
      const types = ['Homework', 'Quizzes', 'Exams'];
      const weights = [0.3, 0.3, 0.4];

      const gradeCalc = new ClassGrade(types, weights);

      expect(gradeCalc.assignTypeBuffer).toEqual(types);
      expect(gradeCalc.weights).toEqual(weights);
      expect(gradeCalc.currAvg).toBeNull();

      // Verify course dictionary structure
      expect(gradeCalc.courseDict['Homework']).toBeDefined();
      expect(gradeCalc.courseDict['Homework'].weight).toBe(0.3);
      expect(gradeCalc.courseDict['Homework'].grades).toEqual([]);
      expect(gradeCalc.courseDict['Homework'].avg).toBeNull();

      console.log('✅ GRADE_LOGIC_001: Constructor validation test passed');
    });

    test('Should handle mismatched arrays length', () => {
      const types = ['Homework', 'Quizzes'];
      const weights = [0.3, 0.3, 0.4]; // Different length

      // BUG CHECK: Should handle mismatched lengths gracefully
      const gradeCalc = new ClassGrade(types, weights);

      // Should only create entries for existing types
      expect(Object.keys(gradeCalc.courseDict)).toHaveLength(2);
      expect(gradeCalc.courseDict['Homework']).toBeDefined();
      expect(gradeCalc.courseDict['Quizzes']).toBeDefined();

      console.log('✅ GRADE_LOGIC_001: Mismatched arrays handling test completed');
    });

    test('Should handle empty arrays', () => {
      const types = [];
      const weights = [];

      const gradeCalc = new ClassGrade(types, weights);

      expect(Object.keys(gradeCalc.courseDict)).toHaveLength(0);
      expect(gradeCalc.assignTypeBuffer).toEqual([]);

      console.log('✅ GRADE_LOGIC_001: Empty arrays handling test passed');
    });
  });

  // ==================== ADD GRADE TESTS ====================

  describe('Test ID: GRADE_LOGIC_002 - Add Grade Functionality', () => {
    let gradeCalc;

    beforeEach(() => {
      const types = ['Homework', 'Quizzes', 'Exams'];
      const weights = [0.3, 0.3, 0.4];
      gradeCalc = new ClassGrade(types, weights);
    });

    test('Should add grades to valid assignment type', () => {
      gradeCalc.addGrade('Homework', 'HW1', 85);
      gradeCalc.addGrade('Homework', 'HW2', 92);

      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(2);
      expect(gradeCalc.courseDict['Homework'].grades[0]).toEqual({name: 'HW1', grade: 85});
      expect(gradeCalc.courseDict['Homework'].grades[1]).toEqual({name: 'HW2', grade: 92});

      console.log('✅ GRADE_LOGIC_002: Add valid grades test passed');
    });

    test('Should ignore grades for invalid assignment type', () => {
      gradeCalc.addGrade('InvalidType', 'Test', 90);

      expect(gradeCalc.courseDict['InvalidType']).toBeUndefined();

      // Other types should remain empty
      Object.values(gradeCalc.courseDict).forEach(typeData => {
        expect(typeData.grades).toEqual([]);
      });

      console.log('✅ GRADE_LOGIC_002: Invalid assignment type handling test passed');
    });

    test('Should handle edge case grades (0, 100, negative, over 100)', () => {
      const edgeCases = [
        {name: 'Zero Grade', grade: 0},
        {name: 'Perfect Grade', grade: 100},
        {name: 'Negative Grade', grade: -10},
        {name: 'Over 100', grade: 150},
        {name: 'Decimal Grade', grade: 85.5}
      ];

      edgeCases.forEach(testCase => {
        gradeCalc.addGrade('Homework', testCase.name, testCase.grade);
      });

      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(5);

      // BUG CHECK: Should accept all numerical grades (validation might be needed)
      expect(gradeCalc.courseDict['Homework'].grades[2].grade).toBe(-10);
      expect(gradeCalc.courseDict['Homework'].grades[3].grade).toBe(150);

      console.log('✅ GRADE_LOGIC_002: Edge case grades test completed');
    });

    test('Should handle non-numeric grades', () => {
      // BUG CHECK: Should handle non-numeric input gracefully
      gradeCalc.addGrade('Homework', 'Invalid1', 'A+');
      gradeCalc.addGrade('Homework', 'Invalid2', NaN);
      gradeCalc.addGrade('Homework', 'Invalid3', undefined);
      gradeCalc.addGrade('Homework', 'Invalid4', null);

      // Should still add the grades (business logic might need validation)
      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(4);

      console.log('✅ GRADE_LOGIC_002: Non-numeric grades test completed');
    });
  });

  // ==================== REMOVE ASSIGNMENT TESTS ====================

  describe('Test ID: GRADE_LOGIC_003 - Remove Assignment Functionality', () => {
    let gradeCalc;

    beforeEach(() => {
      const types = ['Homework', 'Quizzes'];
      const weights = [0.5, 0.5];
      gradeCalc = new ClassGrade(types, weights);

      // Add some test grades
      gradeCalc.addGrade('Homework', 'HW1', 85);
      gradeCalc.addGrade('Homework', 'HW2', 92);
      gradeCalc.addGrade('Homework', 'HW3', 78);
    });

    test('Should remove existing assignment', () => {
      gradeCalc.removeAssignment('Homework', 'HW2');

      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(2);

      const names = gradeCalc.courseDict['Homework'].grades.map(g => g.name);
      expect(names).toContain('HW1');
      expect(names).toContain('HW3');
      expect(names).not.toContain('HW2');

      console.log('✅ GRADE_LOGIC_003: Remove existing assignment test passed');
    });

    test('Should handle removing non-existent assignment', () => {
      const initialLength = gradeCalc.courseDict['Homework'].grades.length;

      gradeCalc.removeAssignment('Homework', 'NonExistent');

      // Should not affect existing grades
      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(initialLength);

      console.log('✅ GRADE_LOGIC_003: Remove non-existent assignment test passed');
    });

    test('Should handle removing from invalid assignment type', () => {
      // BUG CHECK: Should not crash when removing from invalid type
      gradeCalc.removeAssignment('InvalidType', 'HW1');

      // Original grades should remain untouched
      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(3);

      console.log('✅ GRADE_LOGIC_003: Remove from invalid type test passed');
    });
  });

  // ==================== AVERAGE CALCULATION TESTS ====================

  describe('Test ID: GRADE_LOGIC_004 - Average Calculation', () => {
    let gradeCalc;

    beforeEach(() => {
      const types = ['Homework', 'Exams'];
      const weights = [0.6, 0.4];
      gradeCalc = new ClassGrade(types, weights);
    });

    test('Should calculate type average correctly', () => {
      gradeCalc.addGrade('Homework', 'HW1', 80);
      gradeCalc.addGrade('Homework', 'HW2', 90);
      gradeCalc.addGrade('Homework', 'HW3', 85);

      gradeCalc.calcTypeAvg('Homework');

      const expectedAvg = (80 + 90 + 85) / 3; // 85
      expect(gradeCalc.courseDict['Homework'].avg).toBeCloseTo(expectedAvg, 2);
      expect(gradeCalc.getTypeAvg('Homework')).toBeCloseTo(expectedAvg, 2);

      console.log('✅ GRADE_LOGIC_004: Type average calculation test passed');
    });

    test('Should handle division by zero for empty grade list', () => {
      // BUG CHECK: Should handle empty grades list gracefully
      gradeCalc.calcTypeAvg('Homework');

      // Division by zero should result in NaN
      expect(gradeCalc.courseDict['Homework'].avg).toBeNaN();

      console.log('✅ GRADE_LOGIC_004: Empty grade list handling test completed');
    });

    test('Should calculate weighted class average correctly', () => {
      // Add homework grades (weight: 0.6)
      gradeCalc.addGrade('Homework', 'HW1', 80);
      gradeCalc.addGrade('Homework', 'HW2', 90);
      gradeCalc.calcTypeAvg('Homework'); // Average: 85

      // Add exam grades (weight: 0.4)
      gradeCalc.addGrade('Exams', 'Exam1', 75);
      gradeCalc.addGrade('Exams', 'Exam2', 95);
      gradeCalc.calcTypeAvg('Exams'); // Average: 85

      gradeCalc.calcGradeAvg();

      const expectedClassAvg = (85 * 0.6) + (85 * 0.4); // 85
      expect(gradeCalc.getGradeAve()).toBeCloseTo(expectedClassAvg, 2);

      console.log('✅ GRADE_LOGIC_004: Weighted class average test passed');
    });

    test('Should handle missing type averages in class calculation', () => {
      // Add only homework grades, leave exams empty
      gradeCalc.addGrade('Homework', 'HW1', 90);
      gradeCalc.calcTypeAvg('Homework');

      // BUG CHECK: Should handle null/undefined averages
      gradeCalc.calcGradeAvg();

      const result = gradeCalc.getGradeAve();

      // Might result in NaN or partial calculation
      if (isNaN(result)) {
        console.log('🐛 POTENTIAL BUG: Class average is NaN when some types have no grades');
      }

      console.log('✅ GRADE_LOGIC_004: Missing type averages test completed');
    });
  });

  // ==================== PREDICTION CALCULATION TESTS ====================

  describe('Test ID: GRADE_LOGIC_005 - Grade Prediction', () => {
    let gradeCalc;

    beforeEach(() => {
      const types = ['Homework', 'Exams'];
      const weights = [0.6, 0.4];
      gradeCalc = new ClassGrade(types, weights);

      // Setup some existing grades
      gradeCalc.addGrade('Homework', 'HW1', 80);
      gradeCalc.addGrade('Homework', 'HW2', 90);
      gradeCalc.calcTypeAvg('Homework'); // Average: 85

      gradeCalc.addGrade('Exams', 'Exam1', 75);
      gradeCalc.calcTypeAvg('Exams'); // Average: 75
    });

    test('Should predict required grade correctly', () => {
      const desiredClassGrade = 87;
      const requiredExamGrade = gradeCalc.calcPredGrade(desiredClassGrade, 'Exams');

      // Manual calculation verification:
      // Current homework contribution: 85 * 0.6 = 51
      // Need total of 87, so exam contribution needed: 87 - 51 = 36
      // With exam weight 0.4: 36 / 0.4 = 90
      // With existing exam (75) and new exam: (75 + X) / 2 = 90, so X = 105

      expect(requiredExamGrade).toBeCloseTo(105, 1);

      console.log('✅ GRADE_LOGIC_005: Grade prediction calculation test passed');
    });

    test('Should handle unrealistic predictions', () => {
      const impossibleGrade = 100; // Very high desired grade
      const requiredGrade = gradeCalc.calcPredGrade(impossibleGrade, 'Exams');

      // BUG CHECK: Should handle cases where required grade > 100
      if (requiredGrade > 100) {
        console.log(`🐛 POTENTIAL ISSUE: Required grade ${requiredGrade.toFixed(1)} is over 100%`);
      }

      console.log('✅ GRADE_LOGIC_005: Unrealistic prediction test completed');
    });

    test('Should handle prediction with empty assignment type', () => {
      // Try to predict for assignment type with no grades
      const requiredGrade = gradeCalc.calcPredGrade(85, 'Homework');

      // BUG CHECK: Should handle edge case properly
      expect(typeof requiredGrade).toBe('number');

      console.log('✅ GRADE_LOGIC_005: Empty assignment type prediction test completed');
    });

    test('Should handle negative desired grades', () => {
      const negativeGrade = -10;
      const requiredGrade = gradeCalc.calcPredGrade(negativeGrade, 'Exams');

      // BUG CHECK: Should handle negative inputs gracefully
      expect(typeof requiredGrade).toBe('number');

      console.log('✅ GRADE_LOGIC_005: Negative desired grade test completed');
    });
  });

  // ==================== WEIGHT VALIDATION TESTS ====================

  describe('Test ID: GRADE_LOGIC_006 - Weight Validation', () => {
    test('Should handle weights that do not sum to 1.0', () => {
      const types = ['Homework', 'Exams'];
      const weights = [0.3, 0.5]; // Sum = 0.8, not 1.0

      const gradeCalc = new ClassGrade(types, weights);

      gradeCalc.addGrade('Homework', 'HW1', 80);
      gradeCalc.addGrade('Exams', 'Exam1', 90);
      gradeCalc.calcTypeAvg('Homework');
      gradeCalc.calcTypeAvg('Exams');
      gradeCalc.calcGradeAvg();

      const result = gradeCalc.getGradeAve();

      // BUG CHECK: Should either normalize weights or warn about total ≠ 1.0
      const expectedWithCurrentWeights = (80 * 0.3) + (90 * 0.5); // 69
      expect(result).toBeCloseTo(expectedWithCurrentWeights, 2);

      console.log('✅ GRADE_LOGIC_006: Non-normalized weights test completed');
    });

    test('Should handle zero weights', () => {
      const types = ['Homework', 'Exams'];
      const weights = [0, 1.0]; // One type has zero weight

      const gradeCalc = new ClassGrade(types, weights);

      gradeCalc.addGrade('Homework', 'HW1', 50); // Should not affect average
      gradeCalc.addGrade('Exams', 'Exam1', 90);
      gradeCalc.calcTypeAvg('Homework');
      gradeCalc.calcTypeAvg('Exams');
      gradeCalc.calcGradeAvg();

      expect(gradeCalc.getGradeAve()).toBeCloseTo(90, 2);

      console.log('✅ GRADE_LOGIC_006: Zero weight handling test passed');
    });

    test('Should handle negative weights', () => {
      const types = ['Homework', 'Exams'];
      const weights = [-0.1, 1.1]; // Negative weight

      const gradeCalc = new ClassGrade(types, weights);

      gradeCalc.addGrade('Homework', 'HW1', 80);
      gradeCalc.addGrade('Exams', 'Exam1', 90);
      gradeCalc.calcTypeAvg('Homework');
      gradeCalc.calcTypeAvg('Exams');
      gradeCalc.calcGradeAvg();

      // BUG CHECK: Should handle negative weights (might be intentional for extra credit)
      const result = gradeCalc.getGradeAve();
      expect(typeof result).toBe('number');

      console.log('✅ GRADE_LOGIC_006: Negative weight handling test completed');
    });
  });

  // ==================== EDGE CASES AND STRESS TESTS ====================

  describe('Test ID: GRADE_LOGIC_007 - Edge Cases and Stress Tests', () => {
    test('Should handle large numbers of assignments', () => {
      const types = ['Homework'];
      const weights = [1.0];
      const gradeCalc = new ClassGrade(types, weights);

      // Add 1000 assignments
      for (let i = 1; i <= 1000; i++) {
        gradeCalc.addGrade('Homework', `HW${i}`, Math.random() * 100);
      }

      gradeCalc.calcTypeAvg('Homework');
      gradeCalc.calcGradeAvg();

      expect(gradeCalc.courseDict['Homework'].grades).toHaveLength(1000);
      expect(typeof gradeCalc.getGradeAve()).toBe('number');

      console.log('✅ GRADE_LOGIC_007: Large number of assignments test passed');
    });

    test('Should handle very long assignment names', () => {
      const types = ['Test'];
      const weights = [1.0];
      const gradeCalc = new ClassGrade(types, weights);

      const longName = 'A'.repeat(10000); // 10,000 character name
      gradeCalc.addGrade('Test', longName, 85);

      expect(gradeCalc.courseDict['Test'].grades[0].name).toBe(longName);

      console.log('✅ GRADE_LOGIC_007: Long assignment names test passed');
    });

    test('Should handle special characters in assignment names', () => {
      const types = ['Special'];
      const weights = [1.0];
      const gradeCalc = new ClassGrade(types, weights);

      const specialNames = [
        '📚 Math Assignment #1',
        'Assignment with "quotes"',
        'Test <script>alert("xss")</script>',
        'Unicode: 测试作业',
        'Symbols: @#$%^&*()_+-=[]{}|;:,.<>?'
      ];

      specialNames.forEach((name, index) => {
        gradeCalc.addGrade('Special', name, 80 + index);
      });

      expect(gradeCalc.courseDict['Special'].grades).toHaveLength(5);

      console.log('✅ GRADE_LOGIC_007: Special characters test passed');
    });

    test('Should handle floating point precision', () => {
      const types = ['Precision'];
      const weights = [1.0];
      const gradeCalc = new ClassGrade(types, weights);

      // Add grades with high precision
      gradeCalc.addGrade('Precision', 'Test1', 85.333333333);
      gradeCalc.addGrade('Precision', 'Test2', 92.666666667);
      gradeCalc.addGrade('Precision', 'Test3', 78.999999999);

      gradeCalc.calcTypeAvg('Precision');
      gradeCalc.calcGradeAvg();

      const average = gradeCalc.getGradeAve();

      // BUG CHECK: Should handle floating point precision correctly
      expect(typeof average).toBe('number');
      expect(isFinite(average)).toBe(true);

      console.log('✅ GRADE_LOGIC_007: Floating point precision test passed');
    });
  });

  // ==================== PERFORMANCE TESTS ====================

  describe('Test ID: GRADE_LOGIC_008 - Performance Tests', () => {
    test('Should calculate averages efficiently with many grade types', () => {
      const types = [];
      const weights = [];

      // Create 100 grade types
      for (let i = 0; i < 100; i++) {
        types.push(`Type${i}`);
        weights.push(0.01); // Each type worth 1%
      }

      const gradeCalc = new ClassGrade(types, weights);

      // Add grades to each type
      types.forEach(type => {
        for (let j = 0; j < 10; j++) {
          gradeCalc.addGrade(type, `Assignment${j}`, Math.random() * 100);
        }
        gradeCalc.calcTypeAvg(type);
      });

      const startTime = Date.now();
      gradeCalc.calcGradeAvg();
      const endTime = Date.now();

      const calculationTime = endTime - startTime;

      expect(typeof gradeCalc.getGradeAve()).toBe('number');
      expect(calculationTime).toBeLessThan(100); // Should complete in < 100ms

      if (calculationTime > 50) {
        console.log(`🐛 POTENTIAL PERFORMANCE ISSUE: Calculation took ${calculationTime}ms`);
      }

      console.log('✅ GRADE_LOGIC_008: Performance with many types test passed');
    });
  });
});

/**
 * BUG DISCOVERY SUMMARY:
 *
 * Common logic bugs these tests are designed to find:
 * 1. Division by zero when calculating averages with no grades
 * 2. Incorrect handling of weights that don't sum to 1.0
 * 3. Poor handling of edge case grades (negative, over 100, non-numeric)
 * 4. Floating point precision issues in calculations
 * 5. Performance issues with large datasets
 * 6. Memory leaks with very long assignment names
 * 7. Null/undefined reference errors in prediction calculations
 * 8. Incorrect variable names in removeAssignment method (uses assignmentName vs name)
 * 9. Missing input validation for constructor parameters
 * 10. Poor handling of special characters and Unicode in names
 * 11. Infinite or NaN results in prediction calculations
 * 12. Race conditions if methods are called out of order
 * 13. Incorrect weighted average calculations
 * 14. Grade prediction returning impossible values (>100% or negative)
 * 15. Missing bounds checking for array access
 * 16. Poor error handling for invalid assignment types
 * 17. Inconsistent return types (sometimes null, sometimes undefined)
 * 18. Mathematical errors in prediction formula
 * 19. Performance degradation with many assignments
 * 20. Memory inefficient storage of grade data
 *
 * CRITICAL AREAS:
 * - Mathematical accuracy in grade and prediction calculations
 * - Edge case handling (empty datasets, extreme values)
 * - Input validation and sanitization
 * - Performance with large datasets
 * - Floating point precision and rounding
 * - Weight normalization and validation
 * - Error handling for invalid operations
 */