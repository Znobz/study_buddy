# 📚 Study Buddy – Academic Assistant & AI Tutor

A full-stack mobile productivity app helping students manage courses, assignments, study sessions, grades, and multi-modal AI tutoring powered by OpenAI GPT-4o-mini.

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
  - [Core App Features](#-core-app-features)
  - [AI Assistant Module](#-ai-assistant-module)
- [Tech Stack](#️-tech-stack)
- [Project Structure](#-project-structure)
- [Setup Instructions](#-setup-instructions)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [API Endpoints](#-api-endpoints)
  - [Auth](#auth)
  - [Courses](#courses)
  - [Assignments](#assignments)
  - [Study Sessions](#study-sessions)
  - [Grade Calculator](#grade-calculator)
  - [AI Module](#-ai-module)
- [Database Schema](#️-database-schema)
- [Usage Guide](#-usage-guide)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🧠 Overview

Study Buddy is a complete, mobile-first academic assistant designed to streamline student life.

The app integrates:
- Course management
- Assignment tracking
- Study session logging
- Grade calculation & what-if analysis
- A multimodal AI tutor capable of research and image understanding

Built using Flutter, Node.js, and MySQL, Study Buddy is designed for performance, reliability, and ease of use.

## ✨ Features

### 🎓 Core App Features

#### 👤 Authentication
- Secure login with JWT
- Password hashing
- Persistent sessions via SharedPreferences


#### 📝 Assignments
- Create, update, delete assignments
- Status tracking (Not Started → In Progress → Completed)
- Priorities (Low, Medium, High)
- Due dates & descriptions

#### ⏱️ Study Sessions
- Track start/end times
- Planned and actual durations

#### 📊 Grade Calculator
- Weighted grade categories
- Real-time grade updates
- What-if scenarios for final grade planning

#### 📱 UI/UX
- Modern Flutter UI
- Swipe actions
- Responsive layout
- Consistent theme across screens

### 🤖 AI Assistant Module

#### 💬 Conversational AI
- Multiple chat sessions
- Persistent conversation history
- Auto-generated titles
- Manual title editing

#### 🖼️ Image Understanding
- Upload multiple images
- Preview thumbnails
- Full-screen zoom
- AI image analysis & reasoning

#### 🔬 Research Mode
- Web search via Tavily API
- AI adds citations & links
- Real-time information beyond model cutoff

#### 🧩 Multi-modal Intelligence
- Text
- Images
- Mixed messages
- Structured responses when requested

## 🛠️ Tech Stack

### Frontend (Flutter)
- Dart
- http
- shared_preferences
- file_picker
- flutter_markdown
- url_launcher
- http_parser

### Backend (Node.js / Express)
- express
- mysql2
- jsonwebtoken
- multer
- openai (GPT-4o-mini)
- tavily (web research)
- dotenv
- cors

### Database
- MySQL 8.0+

## 📁 Project Structure

```
study_buddy/
├── frontend/
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── course_screen.dart
│   │   │   ├── assignment_screen.dart
│   │   │   ├── study_session_screen.dart
│   │   │   ├── grade_calculator_screen.dart
│   │   │   ├── chat_list_screen.dart
│   │   │   └── ai_tutor_screen.dart
│   │   ├── services/api_service.dart
│   │   ├── models/
│   │   └── widgets/
│   └── pubspec.yaml
│
└── backend/
    ├── src/
    │   ├── config/db.js
    │   ├── middleware/authMiddleware.js
    │   ├── controllers/
    │   │   ├── userController.js
    │   │   ├── courseController.js
    │   │   ├── assignmentController.js
    │   │   ├── gradeController.js
    │   │   ├── studySessionController.js
    │   │   ├── conversationController.js
    │   │   ├── messageController.js
    │   │   └── uploadController.js
    │   ├── routes/
    │   │   ├── authRoutes.js
    │   │   ├── courseRoutes.js
    │   │   ├── assignmentRoutes.js
    │   │   ├── gradeRoutes.js
    │   │   ├── studySessionRoutes.js
    │   │   └── aiRoutes.js
    ├── uploads/
    └── package.json
```

## 🚀 Setup Instructions

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
npm start
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

## 🔌 API Endpoints

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register user |
| POST | `/api/auth/login` | Login + JWT |

### Courses

| Method | Endpoint |
|--------|----------|
| GET | `/api/courses` |
| POST | `/api/courses` |
| PUT | `/api/courses/:id` |
| DELETE | `/api/courses/:id` |

### Assignments

| Method | Endpoint |
|--------|----------|
| GET | `/api/assignments` |
| POST | `/api/assignments` |
| PUT | `/api/assignments/:id` |
| DELETE | `/api/assignments/:id` |

### Study Sessions

| Method | Endpoint |
|--------|----------|
| GET | `/api/sessions` |
| POST | `/api/sessions` |

### Grade Calculator

| Method | Endpoint |
|--------|----------|
| POST | `/api/grades/calculate` |
| POST | `/api/grades/what-if` |

## 🤖 AI Module

### Conversations

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/ai/chats` | Create chat |
| GET | `/api/ai/chats` | List chats |
| GET | `/api/ai/chats/:id` | Get chat |
| POST | `/api/ai/chats/:id/title` | Set title |
| POST | `/api/ai/chats/:id/archive` | Archive chat |

### Messages

| Method | Endpoint |
|--------|----------|
| GET | `/api/ai/chats/:id/messages` |
| POST | `/api/ai/chats/:id/messages` |

### Uploads

| Method | Endpoint |
|--------|----------|
| POST | `/api/ai/uploads` |
| GET | `/api/ai/uploads/:id` |
| DELETE | `/api/ai/uploads/:id` |

## 🗄️ Database Schema

### users

| Field | Type |
|-------|------|
| id | INT PK |
| email | VARCHAR |
| password_hash | VARCHAR |
| first_name | VARCHAR |
| last_name | VARCHAR |
| academic_level | VARCHAR |

### courses

| Field | Type |
|-------|------|
| course_id | INT PK |
| user_id | INT FK |
| course_name | VARCHAR |
| course_code | VARCHAR |
| instructor | VARCHAR |
| semester | VARCHAR |

### assignments

| Field | Type |
|-------|------|
| assignment_id | INT PK |
| course_id | INT FK |
| user_id | INT FK |
| title | VARCHAR |
| description | TEXT |
| priority | ENUM |
| status | ENUM |
| due_date | DATETIME |
| created_at | TIMESTAMP |

### study_sessions

| Field | Type |
|-------|------|
| session_id | INT PK |
| user_id | INT FK |
| course_id | INT FK |
| start_time | DATETIME |
| end_time | DATETIME |
| planned_duration | INT |
| actual_duration | INT |

### grades

| Field | Type |
|-------|------|
| grade_id | INT PK |
| course_id | INT FK |
| category | VARCHAR |
| weight | DECIMAL |
| score | DECIMAL |

### AI Tables
- **conversations**
- **messages** 
- **attachments**

*(Identical to the stable AI schema already implemented.)*

## 🧭 Usage Guide

### Logging In
1. Enter email + password
2. JWT issued and stored locally

### Courses
- Add via "+" button
- Tap course to view assignments

### Assignments
- Add → set priority & due date
- Swipe to delete

### Study Sessions
- Log durations
- Used for productivity metrics

### Grade Calculator
- Add weighted categories
- Test what-if scenarios

### AI Module
- Create chats
- Upload images
- Toggle research mode
- Auto-title generation

## 🐛 Troubleshooting

### 401 Errors
- Missing/expired token
- Ensure `ApiService.loadAuthToken()` loads before `runApp`

### Images Not Displaying
- Add `Authorization: Bearer <token>` header

### Backend Not Responding
Use the correct base URL:

| Platform | URL |
|----------|-----|
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator | `http://localhost:3000/api` |
| Physical Device | `http://YOUR_IP:3000/api` |

## 🤝 Contributing

1. Fork
2. Create feature branch
3. Commit changes
4. Submit PR

## 📄 License

MIT License • © Study Buddy Team
