# Study Buddy Backend

## Setup



1. Copy `.env.example` to `.env` and fill in your credentials.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the dev server:
   ```bash
   npm run dev
   ```
4. API endpoints:
   - POST /api/auth/register
   - POST /api/auth/login
   - GET /api/assignments/:userId
   - POST /api/assignments
   - PUT /api/assignments/:id
   - POST /api/sessions
   - GET /api/sessions/:userId
   - POST /api/ai/ask
   - GET /api/ai/history/:userId
