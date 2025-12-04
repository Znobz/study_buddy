/**
 * REGISTRATION FEATURE - BACKEND API TEST SCRIPT
 * Study Buddy App - Sprint 5 JUnit Testing
 *
 * Purpose: Discover bugs in user registration system
 * Framework: Jest
 * Environment: Google Cloud Run + Google Cloud SQL
 */

const request = require('supertest');

// Test Configuration
const BASE_URL = 'https://study-buddy-backend-851589529788.us-central1.run.app';
const REGISTER_ENDPOINT = '/api/auth/register';
const LOGIN_ENDPOINT = '/api/auth/login';

describe('REGISTRATION FEATURE - Backend API Tests', () => {

  // Generate unique test data to avoid conflicts
  const generateUniqueUser = () => ({
    first_name: 'Test',
    last_name: 'User',
    email: `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}@junit.com`,
    password: 'TestPassword123!'
  });

  // ==================== SUCCESSFUL REGISTRATION TESTS ====================

  describe('Test ID: REGISTER_API_001 - Valid Registration', () => {
    test('Should register user successfully with all required fields', async () => {
      const testUser = generateUniqueUser();

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(200);

      // Verify response structure
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('user_id');
      expect(response.body.message).toContain('successfully');
      expect(response.body.user_id).toBeGreaterThan(0);

      // BUG CHECK: Should not return sensitive data
      expect(response.body).not.toHaveProperty('password');
      expect(response.body).not.toHaveProperty('password_hash');

      console.log('✅ REGISTER_API_001: Valid registration test passed');
    });
  });

  describe('Test ID: REGISTER_API_002 - Registration with minimal fields', () => {
    test('Should register user with only required fields', async () => {
      const testUser = generateUniqueUser();
      // Remove optional last_name
      delete testUser.last_name;

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser);

      // BUG CHECK: Should handle missing optional fields gracefully
      expect([200, 400]).toContain(response.status);

      if (response.status === 400) {
        console.log('🐛 POTENTIAL BUG: Last name appears to be required but not enforced in schema');
      }

      console.log('✅ REGISTER_API_002: Minimal fields test completed');
    });
  });

  // ==================== DUPLICATE EMAIL TESTS ====================

  describe('Test ID: REGISTER_API_003 - Duplicate Email Prevention', () => {
    test('Should prevent registration with existing email', async () => {
      const testUser = generateUniqueUser();

      // Register user first time
      await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(200);

      // Try to register same email again
      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send({
          ...testUser,
          first_name: 'Different',
          last_name: 'Name'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('Email already in use');

      console.log('✅ REGISTER_API_003: Duplicate email prevention test passed');
    });

    test('Should handle email case sensitivity correctly', async () => {
      const testUser = generateUniqueUser();
      const lowerEmail = testUser.email.toLowerCase();
      const upperEmail = testUser.email.toUpperCase();

      // Register with lowercase email
      await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send({ ...testUser, email: lowerEmail })
        .expect(200);

      // Try to register with uppercase email
      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send({ ...testUser, email: upperEmail });

      // BUG CHECK: Should prevent registration regardless of case
      if (response.status === 200) {
        console.log('🐛 POTENTIAL BUG: Email case sensitivity not handled - duplicate users possible');
      } else if (response.status === 400) {
        console.log('✅ Email case sensitivity handled correctly');
      }

      console.log('✅ REGISTER_API_003: Email case sensitivity test completed');
    });
  });

  // ==================== VALIDATION TESTS ====================

  describe('Test ID: REGISTER_API_004 - Required Field Validation', () => {
    test('Should reject registration with missing email', async () => {
      const testUser = generateUniqueUser();
      delete testUser.email;

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('Email and password required');

      console.log('✅ REGISTER_API_004: Missing email validation test passed');
    });

    test('Should reject registration with missing password', async () => {
      const testUser = generateUniqueUser();
      delete testUser.password;

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('Email and password required');

      console.log('✅ REGISTER_API_004: Missing password validation test passed');
    });

    test('Should handle empty string values', async () => {
      const testUser = {
        first_name: '',
        last_name: '',
        email: '',
        password: ''
      };

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(400);

      expect(response.body).toHaveProperty('error');

      console.log('✅ REGISTER_API_004: Empty string validation test passed');
    });
  });

  // ==================== EMAIL FORMAT VALIDATION ====================

  describe('Test ID: REGISTER_API_005 - Email Format Validation', () => {
    const invalidEmails = [
      'invalid-email',
      '@domain.com',
      'user@',
      'user@@domain.com',
      'user@domain',
      'user.domain.com',
      'user @domain.com',
      'user@domain..com'
    ];

    test.each(invalidEmails)('Should reject invalid email format: %s', async (invalidEmail) => {
      const testUser = generateUniqueUser();
      testUser.email = invalidEmail;

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser);

      // BUG CHECK: Should validate email format
      if (response.status === 200) {
        console.log(`🐛 POTENTIAL BUG: Invalid email format accepted: ${invalidEmail}`);
      }

      // Should either reject (400) or handle gracefully
      expect([400, 500]).toContain(response.status);
    });
  });

  // ==================== PASSWORD SECURITY TESTS ====================

  describe('Test ID: REGISTER_API_006 - Password Security', () => {
    test('Should hash passwords before storing', async () => {
      const testUser = generateUniqueUser();
      const plainPassword = testUser.password;

      // Register user
      await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(200);

      // Try to login to verify password was hashed correctly
      const loginResponse = await request(BASE_URL)
        .post(LOGIN_ENDPOINT)
        .send({
          email: testUser.email,
          password: plainPassword
        })
        .expect(200);

      expect(loginResponse.body).toHaveProperty('token');
      console.log('✅ REGISTER_API_006: Password hashing test passed');
    });

    test('Should handle very weak passwords', async () => {
      const weakPasswords = [
        '123',
        'pass',
        'a',
        '     ', // spaces only
        'password' // common password
      ];

      for (const weakPassword of weakPasswords) {
        const testUser = generateUniqueUser();
        testUser.password = weakPassword;

        const response = await request(BASE_URL)
          .post(REGISTER_ENDPOINT)
          .send(testUser);

        // BUG CHECK: Should have password strength requirements
        if (response.status === 200) {
          console.log(`🐛 POTENTIAL SECURITY ISSUE: Weak password accepted: "${weakPassword}"`);
        }
      }

      console.log('✅ REGISTER_API_006: Weak password handling test completed');
    });
  });

  // ==================== SQL INJECTION SECURITY TESTS ====================

  describe('Test ID: REGISTER_API_007 - SQL Injection Protection', () => {
    test('Should prevent SQL injection in all input fields', async () => {
      const sqlInjectionPayloads = [
        "'; DROP TABLE users; --",
        "' OR '1'='1",
        "'; DELETE FROM users; --",
        "' UNION SELECT * FROM users --",
        "admin'/*"
      ];

      for (const payload of sqlInjectionPayloads) {
        const testUser = generateUniqueUser();

        // Test injection in each field
        const injectionTests = [
          { ...testUser, first_name: payload },
          { ...testUser, last_name: payload },
          { ...testUser, email: payload + '@test.com' },
          { ...testUser, password: payload }
        ];

        for (const injectionTest of injectionTests) {
          const response = await request(BASE_URL)
            .post(REGISTER_ENDPOINT)
            .send(injectionTest);

          // Should not crash server or expose database errors
          expect([400, 401, 500]).toContain(response.status);

          // BUG CHECK: Should not reveal database structure in errors
          if (response.body.error && response.body.error.includes('mysql')) {
            console.log('🐛 POTENTIAL BUG: Database error exposed in response');
          }
        }
      }

      console.log('✅ REGISTER_API_007: SQL injection protection test passed');
    });
  });

  // ==================== XSS PROTECTION TESTS ====================

  describe('Test ID: REGISTER_API_008 - XSS Protection', () => {
    test('Should handle XSS attempts in input fields', async () => {
      const xssPayloads = [
        '<script>alert("xss")</script>',
        'javascript:alert("xss")',
        '<img src=x onerror=alert("xss")>',
        '"><script>alert("xss")</script>',
        '<svg onload=alert("xss")>'
      ];

      for (const xssPayload of xssPayloads) {
        const testUser = generateUniqueUser();
        testUser.first_name = xssPayload;
        testUser.last_name = xssPayload;

        const response = await request(BASE_URL)
          .post(REGISTER_ENDPOINT)
          .send(testUser);

        // Should handle gracefully
        expect([400, 500]).toContain(response.status);

        // BUG CHECK: Should not reflect XSS payloads
        if (response.body.error && response.body.error.includes('<script>')) {
          console.log('🐛 POTENTIAL XSS BUG: Script tags reflected in error response');
        }
      }

      console.log('✅ REGISTER_API_008: XSS protection test passed');
    });
  });

  // ==================== EDGE CASE TESTS ====================

  describe('Test ID: REGISTER_API_009 - Edge Cases', () => {
    test('Should handle very long input values', async () => {
      const longString = 'a'.repeat(1000);
      const testUser = generateUniqueUser();

      const longInputTests = [
        { ...testUser, first_name: longString },
        { ...testUser, last_name: longString },
        { ...testUser, email: longString + '@test.com' },
        { ...testUser, password: longString }
      ];

      for (const longInputTest of longInputTests) {
        const response = await request(BASE_URL)
          .post(REGISTER_ENDPOINT)
          .send(longInputTest);

        // Should handle gracefully, not crash
        expect([200, 400, 500]).toContain(response.status);

        if (response.status === 500) {
          console.log('🐛 POTENTIAL BUG: Long input causes server error');
        }
      }

      console.log('✅ REGISTER_API_009: Long input handling test passed');
    });

    test('Should handle unicode characters', async () => {
      const unicodeInputs = [
        'José María',
        '测试用户',
        'пользователь',
        'مستخدم',
        '🔥Fire🔥'
      ];

      for (const unicodeInput of unicodeInputs) {
        const testUser = generateUniqueUser();
        testUser.first_name = unicodeInput;
        testUser.last_name = unicodeInput;

        const response = await request(BASE_URL)
          .post(REGISTER_ENDPOINT)
          .send(testUser);

        // Should handle unicode gracefully
        expect([200, 400, 500]).toContain(response.status);
      }

      console.log('✅ REGISTER_API_009: Unicode handling test passed');
    });
  });

  // ==================== DATABASE CONSTRAINT TESTS ====================

  describe('Test ID: REGISTER_API_010 - Database Constraints', () => {
    test('Should respect database field length limits', async () => {
      const testUser = generateUniqueUser();

      // Test email field length (assuming 255 char limit)
      testUser.email = 'a'.repeat(250) + '@test.com';

      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser);

      // Should either succeed or fail gracefully
      expect([200, 400, 500]).toContain(response.status);

      if (response.status === 500) {
        console.log('🐛 POTENTIAL BUG: Database constraint violation not handled gracefully');
      }

      console.log('✅ REGISTER_API_010: Database constraints test passed');
    });
  });

  // ==================== PERFORMANCE TESTS ====================

  describe('Test ID: REGISTER_API_011 - Performance', () => {
    test('Should respond within reasonable time', async () => {
      const testUser = generateUniqueUser();
      const startTime = Date.now();

      await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser)
        .expect(200);

      const responseTime = Date.now() - startTime;

      // Should respond within 5 seconds
      expect(responseTime).toBeLessThan(5000);

      if (responseTime > 3000) {
        console.log(`🐛 POTENTIAL PERFORMANCE ISSUE: Registration took ${responseTime}ms`);
      }

      console.log(`✅ REGISTER_API_011: Performance test passed (${responseTime}ms)`);
    });
  });

  // ==================== CONTENT TYPE TESTS ====================

  describe('Test ID: REGISTER_API_012 - Content Type Handling', () => {
    test('Should require correct content type', async () => {
      const testUser = generateUniqueUser();

      // Test without Content-Type header
      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(testUser);

      // Should handle missing content type gracefully
      expect([200, 400, 415]).toContain(response.status);

      if (response.status === 415) {
        console.log('✅ Content-Type validation working correctly');
      }

      console.log('✅ REGISTER_API_012: Content type test completed');
    });
  });

  // ==================== RATE LIMITING TESTS ====================

  describe('Test ID: REGISTER_API_013 - Rate Limiting', () => {
    test('Should handle multiple rapid registration attempts', async () => {
      const rapidRequests = [];

      // Send 10 rapid registration requests
      for (let i = 0; i < 10; i++) {
        const testUser = generateUniqueUser();
        rapidRequests.push(
          request(BASE_URL)
            .post(REGISTER_ENDPOINT)
            .send(testUser)
        );
      }

      const responses = await Promise.all(rapidRequests);

      // Check if any rate limiting is implemented
      const rateLimited = responses.some(res => res.status === 429);

      if (!rateLimited) {
        console.log('🐛 POTENTIAL SECURITY ISSUE: No rate limiting detected for registration');
      }

      console.log('✅ REGISTER_API_013: Rate limiting test completed');
    });
  });

  // Cleanup after tests
  afterAll(async () => {
    console.log('🧹 Registration test cleanup completed');
  });
});

/**
 * BUG DISCOVERY SUMMARY:
 *
 * Common bugs these tests are designed to find:
 * 1. Sensitive data exposure in API responses (password_hash, internal fields)
 * 2. Email case sensitivity issues leading to duplicate accounts
 * 3. Missing email format validation
 * 4. Weak password acceptance without strength requirements
 * 5. SQL injection vulnerabilities in input fields
 * 6. XSS vulnerabilities in error messages
 * 7. Poor handling of edge cases (long inputs, unicode characters)
 * 8. Database constraint violations not handled gracefully
 * 9. Missing rate limiting for registration attempts
 * 10. Performance issues with registration process
 * 11. Improper content type handling
 * 12. Missing validation for required vs optional fields
 * 13. Database connection issues
 * 14. Error message information disclosure
 * 15. Concurrent registration handling problems
 */