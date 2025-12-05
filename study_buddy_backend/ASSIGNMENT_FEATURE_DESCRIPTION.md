# Assignment Feature: Technical Overview

## How the Assignment Feature Works

The assignment feature allows students to create, view, and manage their academic assignments through a mobile app, with all data securely stored and synchronized via a backend API.

### Frontend (Flutter Mobile App)

**User Interface:**
- The `AssignmentsScreen` displays a list of all assignments in a scrollable card layout
- Each assignment card shows the title, description, due date, and a delete button
- A floating action button opens a dialog to create new assignments
- When creating an assignment, users must provide:
  - **Title** (required)
  - **Description** (optional)
  - **Due Date** (required, selected via date picker)

**Data Flow in Frontend:**
1. When the screen loads, it calls `ApiService.getAssignments()` which sends an HTTP GET request to the backend
2. The response (JSON array of assignments) is stored in the app's state and displayed
3. When a user creates a new assignment, the form data is sent via `ApiService.addAssignment()` as an HTTP POST request
4. After successful creation, the app automatically refreshes the list and schedules a notification reminder
5. Deleting an assignment sends an HTTP DELETE request with the assignment ID

### Backend API (Node.js/Express)

**API Endpoints:**
The backend exposes RESTful endpoints at `/api/assignments`:

- **GET `/api/assignments`** - Retrieves all assignments for the authenticated user
- **POST `/api/assignments`** - Creates a new assignment
- **PUT `/api/assignments/:id`** - Updates an existing assignment
- **DELETE `/api/assignments/:id`** - Deletes an assignment

**Request Flow:**
1. **Authentication Middleware:** Every request first passes through `verifyToken` middleware, which validates the JWT token to ensure the user is logged in
2. **Route Handler:** Express routes (`assignmentRoutes.js`) receive the HTTP request and call the appropriate controller function
3. **Controller Logic:** The `assignmentController.js` handles business logic:
   - Validates required fields (title and due_date are mandatory)
   - Normalizes date format to ensure consistency (YYYY-MM-DD)
   - Ensures a default "General" course exists for the user if no course is specified
   - Handles optional file attachments using Multer middleware
4. **Database Operations:** The controller uses MySQL connection pool to execute SQL queries:
   - **SELECT** queries retrieve assignments filtered by user_id
   - **INSERT** queries create new assignment records
   - **UPDATE** queries modify existing assignments
   - **DELETE** queries remove assignments
5. **Response:** The controller sends back JSON responses with appropriate HTTP status codes (200 for success, 400 for validation errors, 500 for server errors)

### Database (MySQL)

**Schema:**
Assignments are stored in the `assignments` table with the following key fields:
- `assignment_id` (primary key, auto-increment)
- `user_id` (foreign key linking to the user)
- `course_id` (foreign key linking to courses)
- `title` (required)
- `description` (optional text)
- `due_date` (required, stored as DATETIME)
- `priority` (defaults to 'medium')
- `status` (defaults to 'pending')
- `file_path` and `file_name` (for optional attachments)
- `created_at` (timestamp)

**Data Relationships:**
- Each assignment belongs to one user (via `user_id`)
- Each assignment belongs to one course (via `course_id`)
- If no course is specified, the system automatically creates/uses a "General" course

### Communication Protocol

**HTTP/JSON Communication:**
- The Flutter app communicates with the backend using standard HTTP methods
- All data is transmitted as JSON (JavaScript Object Notation)
- The backend API uses RESTful principles (GET for reading, POST for creating, PUT for updating, DELETE for deleting)
- Authentication is handled via JWT (JSON Web Tokens) passed in the `Authorization` header

**Example Request/Response:**

**Creating an Assignment:**
```
POST /api/assignments
Headers: { Authorization: "Bearer <token>", Content-Type: "application/json" }
Body: {
  "title": "CS Lab 3",
  "description": "Submit circuits report",
  "due_date": "2025-11-20"
}

Response (201 Created):
{
  "assignment_id": 100,
  "user_id": 1,
  "title": "CS Lab 3",
  "due_date": "2025-11-20",
  "status": "pending",
  "priority": "medium"
}
```

### Security & Validation

**Security Measures:**
- All endpoints require authentication via JWT tokens
- User ID is extracted from the token, ensuring users can only access their own assignments
- SQL queries use parameterized statements to prevent SQL injection attacks
- File uploads are limited to 50MB and stored in a secure uploads directory

**Validation:**
- Frontend validates that title and due_date are provided before sending the request
- Backend performs server-side validation to ensure data integrity
- Date format is normalized to prevent inconsistencies
- Required fields are enforced at both frontend and backend levels

### Integration Points

**How Frontend and Backend Connect:**
1. **API Service Layer:** The Flutter app uses an `ApiService` class that abstracts HTTP communication, handling token management and request formatting
2. **State Management:** The Flutter screen uses stateful widgets to manage loading states and assignment lists
3. **Error Handling:** Both frontend and backend implement try-catch blocks to handle network errors, validation failures, and server errors gracefully
4. **Notifications:** After creating an assignment, the app schedules a local notification reminder using the device's notification service

This architecture ensures separation of concerns: the mobile app handles user interaction and display, while the backend manages business logic, data validation, and database operations, creating a scalable and maintainable system.

