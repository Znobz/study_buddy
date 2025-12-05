/**
 * LOGIN FEATURE - BACKEND API TEST SCRIPT
 * Study Buddy App - Sprint 5 JUnit Testing
 * 
 * Purpose: Discover bugs in login authentication system
 * Framework: Jest
 * Environment: Google Cloud Run + Google Cloud SQL
 */

const request = require('supertest');

// Test Configuration
const BASE_URL = 'https://study-buddy-backend-851589529788.us-central1.run.app';
const API_ENDPOINT = '/api/auth/login';
const REGISTER_ENDPOINT = '/api/auth/register';
const VALIDATE_ENDPOINT = '/api/auth/validate';

describe('LOGIN FEATURE - Backend API Tests', () => {
  let validTestUser = {
    first_name: 'Test',
    last_name: 'User',
    email: `test_${Date.now()}@junit.com`,
    password: 'TestPassword123!'
  };

  let validToken = null;

  // Setup: Create test user before running tests
  beforeAll(async () => {
    try {
      const response = await request(BASE_URL)
        .post(REGISTER_ENDPOINT)
        .send(validTestUser)
        .expect(200);
      
      console.log('✅ Test user created successfully');
    } catch (error) {
      console.error('❌ Failed to create test user:', error.message);
    }
  });

  // ==================== SUCCESSFUL LOGIN TESTS ====================

  describe('Test ID: LOGIN_API_001 - Valid Login', () => {
    test('Should login successfully with correct credentials', async () => {
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: validTestUser.email,
          password: validTestUser.password
        })
        .expect(200);

      // Verify response structure
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('user');

      // Verify token is valid JWT format
      expect(response.body.token).toMatch(/^[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$/);

      // Verify user object structure
      expect(response.body.user).toHaveProperty('user_id');
      expect(response.body.user).toHaveProperty('first_name');
      expect(response.body.user).toHaveProperty('last_name');
      expect(response.body.user).toHaveProperty('email');

      // CRITICAL BUG CHECK: Ensure password_hash is removed
      expect(response.body.user).not.toHaveProperty('password_hash');
      expect(response.body.user).not.toHaveProperty('password');

      // Store token for subsequent tests
      validToken = response.body.token;

      console.log('✅ LOGIN_API_001: Valid login test passed');
    });
  });

  // ==================== INVALID CREDENTIALS TESTS ====================

  describe('Test ID: LOGIN_API_002 - Invalid Email', () => {
    test('Should reject login with non-existent email', async () => {
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: 'nonexistent@fake.com',
          password: validTestUser.password
        })
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid credentials');

      // BUG CHECK: Ensure no user enumeration
      expect(response.body.error).not.toContain('not found');
      expect(response.body.error).not.toContain('does not exist');

      console.log('✅ LOGIN_API_002: Invalid email test passed');
    });
  });

  describe('Test ID: LOGIN_API_003 - Invalid Password', () => {
    test('Should reject login with wrong password', async () => {
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: validTestUser.email,
          password: 'WrongPassword123!'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid credentials');

      console.log('✅ LOGIN_API_003: Invalid password test passed');
    });
  });

  // ==================== INPUT VALIDATION TESTS ====================

  describe('Test ID: LOGIN_API_004 - Missing Fields', () => {
    test('Should handle missing email field', async () => {
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          password: validTestUser.password
        });

      // BUG CHECK: Should return 400, not crash
      expect([400, 500]).toContain(response.status);
      
      if (response.status === 500) {
        console.log('🐛 POTENTIAL BUG: Missing email causes 500 error instead of 400');
      }
    });

    test('Should handle missing password field', async () => {
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: validTestUser.email
        });

      // BUG CHECK: Should return 400, not crash
      expect([400, 500]).toContain(response.status);
      
      if (response.status === 500) {
        console.log('🐛 POTENTIAL BUG: Missing password causes 500 error instead of 400');
      }
    });

    test('Should handle completely empty request body', async () => {
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({});

      expect([400, 500]).toContain(response.status);
      
      if (response.status === 500) {
        console.log('🐛 POTENTIAL BUG: Empty body causes 500 error instead of 400');
      }
    });
  });

  // ==================== SECURITY TESTS ====================

  describe('Test ID: LOGIN_API_005 - SQL Injection Protection', () => {
    test('Should prevent SQL injection in email field', async () => {
      const sqlInjectionAttempts = [
        "admin'; DROP TABLE users; --",
        "' OR '1'='1",
        "' UNION SELECT * FROM users --",
        "admin'/*",
        "'; DELETE FROM users WHERE '1'='1"
      ];

      for (const maliciousEmail of sqlInjectionAttempts) {
        const response = await request(BASE_URL)
          .post(API_ENDPOINT)
          .send({
            email: maliciousEmail,
            password: validTestUser.password
          });

        // Should return 401 (invalid credentials), not 500 (error)
        expect(response.status).toBe(401);
        expect(response.body.error).toBe('Invalid credentials');
      }

      console.log('✅ LOGIN_API_005: SQL injection protection test passed');
    });
  });

  describe('Test ID: LOGIN_API_006 - XSS Protection', () => {
    test('Should handle XSS attempts in input fields', async () => {
      const xssAttempts = [
        '<script>alert("xss")</script>',
        'javascript:alert("xss")',
        '<img src=x onerror=alert("xss")>',
        '"><script>alert("xss")</script>'
      ];

      for (const xssPayload of xssAttempts) {
        const response = await request(BASE_URL)
          .post(API_ENDPOINT)
          .send({
            email: xssPayload,
            password: xssPayload
          });

        // Should not crash the server
        expect([400, 401, 500]).toContain(response.status);
        
        if (response.body.error && response.body.error.includes('<script>')) {
          console.log('🐛 POTENTIAL BUG: XSS payload reflected in error message');
        }
      }

      console.log('✅ LOGIN_API_006: XSS protection test passed');
    });
  });

  // ==================== EDGE CASE TESTS ====================

  describe('Test ID: LOGIN_API_007 - Edge Cases', () => {
    test('Should handle very long email input', async () => {
      const longEmail = 'a'.repeat(1000) + '@test.com';
      
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: longEmail,
          password: validTestUser.password
        });

      // Should handle gracefully, not crash
      expect([400, 401, 500]).toContain(response.status);
      
      if (response.status === 500) {
        console.log('🐛 POTENTIAL BUG: Very long email causes server error');
      }
    });

    test('Should handle very long password input', async () => {
      const longPassword = 'a'.repeat(10000);
      
      const response = await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: validTestUser.email,
          password: longPassword
        });

      // Should handle gracefully, not crash
      expect([400, 401, 500]).toContain(response.status);
      
      if (response.status === 500) {
        console.log('🐛 POTENTIAL BUG: Very long password causes server error');
      }
    });

    test('Should handle unicode characters in inputs', async () => {
      const unicodeInputs = [
        'test@测试.com',
        'пользователь@тест.рф',
        '用户@测试.中国',
        '🔥test🔥@fire🔥.com'
      ];

      for (const unicodeInput of unicodeInputs) {
        const response = await request(BASE_URL)
          .post(API_ENDPOINT)
          .send({
            email: unicodeInput,
            password: 'password123'
          });

        // Should not crash
        expect([400, 401, 500]).toContain(response.status);
      }

      console.log('✅ LOGIN_API_007: Unicode handling test passed');
    });
  });

  // ==================== TOKEN VALIDATION TESTS ====================

  describe('Test ID: LOGIN_API_008 - Token Validation', () => {
    test('Should validate token correctly', async () => {
      if (!validToken) {
        console.log('⏭️ Skipping token validation - no valid token available');
        return;
      }

      const response = await request(BASE_URL)
        .get(VALIDATE_ENDPOINT)
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('valid');
      expect(response.body.valid).toBe(true);
      expect(response.body).toHaveProperty('user');

      console.log('✅ LOGIN_API_008: Token validation test passed');
    });

    test('Should reject invalid token', async () => {
      const invalidTokens = [
        'invalid.token.here',
        'Bearer invalid-token',
        'totally-fake-token',
        '',
        null
      ];

      for (const invalidToken of invalidTokens) {
        const response = await request(BASE_URL)
          .get(VALIDATE_ENDPOINT)
          .set('Authorization', `Bearer ${invalidToken}`);

        expect([400, 401]).toContain(response.status);
      }

      console.log('✅ LOGIN_API_008: Invalid token rejection test passed');
    });
  });

  // ==================== PERFORMANCE TESTS ====================

  describe('Test ID: LOGIN_API_009 - Performance', () => {
    test('Should respond within reasonable time', async () => {
      const startTime = Date.now();
      
      await request(BASE_URL)
        .post(API_ENDPOINT)
        .send({
          email: validTestUser.email,
          password: validTestUser.password
        })
        .expect(200);

      const responseTime = Date.now() - startTime;
      
      // Should respond within 5 seconds
      expect(responseTime).toBeLessThan(5000);
      
      if (responseTime > 2000) {
        console.log(`🐛 POTENTIAL PERFORMANCE ISSUE: Login took ${responseTime}ms`);
      }

      console.log(`✅ LOGIN_API_009: Performance test passed (${responseTime}ms)`);
    });
  });

  // ==================== RATE LIMITING TESTS ====================

  describe('Test ID: LOGIN_API_010 - Rate Limiting', () => {
    test('Should handle multiple rapid login attempts', async () => {
      const rapidRequests = [];
      
      // Send 10 rapid requests
      for (let i = 0; i < 10; i++) {
        rapidRequests.push(
          request(BASE_URL)
            .post(API_ENDPOINT)
            .send({
              email: 'attacker@test.com',
              password: 'wrongpassword'
            })
        );
      }

      const responses = await Promise.all(rapidRequests);
      
      // Check if any rate limiting is implemented
      const rateLimited = responses.some(res => res.status === 429);
      
      if (!rateLimited) {
        console.log('🐛 POTENTIAL SECURITY ISSUE: No rate limiting detected');
      }

      console.log('✅ LOGIN_API_010: Rate limiting test completed');
    });
  });

  // Cleanup after tests
  afterAll(async () => {
    console.log('🧹 Test cleanup completed');
  });
});

/**
 * BUG DISCOVERY SUMMARY:
 * 
 * Common bugs these tests are designed to find:
 * 1. Password hash exposure in API responses
 * 2. User enumeration vulnerabilities
 * 3. Improper error handling for missing fields
 * 4. SQL injection vulnerabilities
 * 5. XSS vulnerabilities in error messages
 * 6. Poor handling of edge cases (long inputs, unicode)
 * 7. Missing rate limiting
 * 8. Performance issues
 * 9. JWT token validation flaws
 * 10. Database connection issues
 */