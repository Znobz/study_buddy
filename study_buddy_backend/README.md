# Study Buddy Backend

## Prerequisites
- Node.js (v14 or higher)
- MySQL database
- npm or yarn

## Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Database Setup
**IMPORTANT**: You need to set up the database before running the server.

#### Option A: Automatic Setup (Recommended)
```bash
node setup-db.js
```

#### Option B: Manual Setup
1. Create a MySQL database named `study_buddy`
2. Run the SQL commands in `db/schema.sql` to create tables

### 3. Environment Configuration
Create a `.env` file with your database credentials:
```env
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=study_buddy
JWT_SECRET=your_jwt_secret_key
PORT=3000
```

### 4. Start the Server

#### Option A: Easy Startup (Recommended)
```bash
node start-server.js
```

#### Option B: Manual Startup
```bash
node src/server.js
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/validate` - Validate JWT token

### Assignments
- `GET /api/assignments` - Get user assignments
- `POST /api/assignments` - Create assignment
- `PUT /api/assignments/:id` - Update assignment
- `DELETE /api/assignments/:id` - Delete assignment

### Study Sessions
- `GET /api/sessions` - Get study sessions
- `POST /api/sessions` - Create study session
- `DELETE /api/sessions/:id` - Delete study session

### AI Tutor
- `POST /api/ai/ask` - Ask AI tutor
- `GET /api/ai/history/:userId` - Get chat history

## Troubleshooting

### Database Connection Issues
- Make sure MySQL is running
- Check your database credentials in `.env`
- Ensure the `study_buddy` database exists

### Server Won't Start
- Check if port 3000 is available
- Verify all dependencies are installed
- Check console for error messages

### Authentication Issues
- Make sure JWT_SECRET is set in `.env`
- Verify database tables are created
- Check if user exists in database

## Development Notes

- The server runs on `http://localhost:3000`
- All API endpoints are prefixed with `/api`
- Authentication is required for most endpoints
- CORS is enabled for frontend development
