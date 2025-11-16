📚 Study Buddy - AI Assistant ModuleA Flutter mobile app with an intelligent AI tutor powered by OpenAI GPT-4o-mini, featuring multi-modal conversations, web research, and image analysis.✨ Features🤖 AI Chat

Multi-conversation support - Create and manage multiple chat sessions
Persistent chat history - All conversations saved to MySQL database
Auto-generated titles - AI automatically names your chats based on content
Manual title editing - Rename chats anytime with tap-to-edit
🖼️ Image Understanding

Multiple image upload - Send multiple images in a single message
Image analysis - AI can describe, analyze, and answer questions about images
Thumbnail preview - See uploaded images before sending
Full-screen zoom - Tap images to view in full screen with pinch-to-zoom
🔬 Research Mode

Web search integration - AI searches the web using Tavily API
Source citations - Every researched answer includes clickable sources
Real-time information - Get current data beyond AI's knowledge cutoff
💅 Modern UI/UX

Markdown formatting - Rich text with bold, italic, lists, code blocks
Optimistic updates - Instant UI feedback while waiting for server
Swipe to delete - Delete chats with confirmation dialog
Loading states - Clear indicators for ongoing operations
Error handling - Graceful fallbacks with user-friendly messages
🛠️ Tech StackFrontend

Flutter/Dart - Cross-platform mobile framework
http - API communication
shared_preferences - Local token storage
file_picker - Image/file selection
url_launcher - Open research sources in browser
flutter_markdown - Rich text rendering
http_parser - MIME type handling for uploads
Backend

Node.js + Express - REST API server
MySQL - Relational database (mysql2/promise)
OpenAI API - GPT-4o-mini for AI responses
Tavily API - Web search for research mode
JWT - Authentication tokens
Multer - Multipart file uploads
📁 Project Structurestudy_buddy/
├── frontend/ (Flutter)
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── chat_list_screen.dart    # Chat list with create/delete
│   │   │   └── ai_tutor_screen.dart     # Chat conversation UI
│   │   └── services/
│   │       └── api_service.dart         # HTTP client & API methods
│   └── pubspec.yaml
│
└── backend/ (Node.js)
    ├── src/
    │   ├── config/
    │   │   └── db.js                    # MySQL connection
    │   ├── controllers/
    │   │   ├── conversationController.js # Chat CRUD + auto-title
    │   │   ├── messageController.js     # Messages + AI logic
    │   │   └── uploadController.js      # File uploads
    │   ├── routes/
    │   │   └── aiRoutes.js              # API route definitions
    │   └── middleware/
    │       └── authMiddleware.js        # JWT verification
    └── package.json🚀 Setup InstructionsPrerequisites

Flutter SDK (3.0+)
Node.js (18+)
MySQL (8.0+)
OpenAI API key
Tavily API key (for research mode)
Backend Setup
Navigate to backend directory:

bash   cd study_buddy_backend
Install dependencies:

bash   npm install
Create .env file:

env   PORT=3000
   DB_HOST=localhost
   DB_USER=your_mysql_user
   DB_PASSWORD=your_mysql_password
   DB_NAME=study_buddy
   JWT_SECRET=your_jwt_secret_key
   OPENAI_API_KEY=sk-...
   TAVILY_API_KEY=tvly-...
Set up MySQL database:

sql   CREATE DATABASE study_buddy;
   USE study_buddy;

   CREATE TABLE conversations (
     id INT PRIMARY KEY AUTO_INCREMENT,
     user_id INT NOT NULL,
     title VARCHAR(255) DEFAULT 'New Chat',
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
     is_archived BOOLEAN DEFAULT FALSE
   );

   CREATE TABLE messages (
     id INT PRIMARY KEY AUTO_INCREMENT,
     conversation_id INT NOT NULL,
     role ENUM('user', 'assistant') NOT NULL,
     text TEXT,
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     attachment_ids JSON,
     FOREIGN KEY (conversation_id) REFERENCES conversations(id)
   );

   CREATE TABLE attachments (
     id INT PRIMARY KEY AUTO_INCREMENT,
     conversation_id INT NOT NULL,
     file_path VARCHAR(500) NOT NULL,
     file_name VARCHAR(255) NOT NULL,
     mime_type VARCHAR(100),
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     FOREIGN KEY (conversation_id) REFERENCES conversations(id)
   );
Start the server:

bash   npm start
Server runs on http://localhost:3000Frontend Setup
Navigate to frontend directory:

bash   cd study_buddy_app
Install dependencies:

bash   flutter pub get
Update base URL (if needed):
In lib/services/api_service.dart:

dart   final String baseUrl = "http://10.0.2.2:3000/api";  // Android emulator
   // OR
   final String baseUrl = "http://localhost:3000/api";  // iOS simulator
Run the app:

bash   flutter run🔌 API EndpointsConversations
MethodEndpointDescriptionPOST/api/ai/chatsCreate new chatGET/api/ai/chatsList user's chatsGET/api/ai/chats/:idGet chat detailsPOST/api/ai/chats/:id/archiveArchive/delete chatPOST/api/ai/chats/:id/titleAuto-generate or set titleMessages
MethodEndpointDescriptionGET/api/ai/chats/:id/messagesGet chat messagesPOST/api/ai/chats/:id/messagesSend message (text/images)Uploads
MethodEndpointDescriptionPOST/api/ai/uploadsUpload image/fileGET/api/ai/uploads/:idRetrieve attachmentDELETE/api/ai/uploads/:idDelete attachment📖 UsageCreating a Chat

Tap the + button (FAB or AppBar)
Chat appears immediately with "New Chat" title
Start sending messages
Sending a Message

Type your question in the text field
(Optional) Tap 📎 to attach images
Tap Send button
AI responds with formatted text
Using Research Mode

Tap the 🔬 science icon in the AppBar
Icon turns yellow when enabled
Ask questions requiring current information
AI searches the web and provides sources
Uploading Images

Tap the 📎 attachment icon
Select one or multiple images
Preview appears below text field
Tap X to remove individual images
Send with or without text
Editing Chat Title

Tap the chat title in the AppBar
Enter new title in dialog
Tap Save
🗄️ Database Schemaconversations Table
sqlid              INT (PK, AUTO_INCREMENT)
user_id         INT (FK)
title           VARCHAR(255)
created_at      DATETIME
updated_at      DATETIME
is_archived     BOOLEANmessages Table
sqlid              INT (PK, AUTO_INCREMENT)
conversation_id INT (FK)
role            ENUM('user', 'assistant')
text            TEXT
created_at      DATETIME
attachment_ids  JSONattachments Table
sqlid              INT (PK, AUTO_INCREMENT)
conversation_id INT (FK)
file_path       VARCHAR(500)
file_name       VARCHAR(255)
mime_type       VARCHAR(100)
created_at      DATETIME🔑 Key Implementation DetailsAuthentication

JWT tokens stored in SharedPreferences
Token sent in Authorization: Bearer <token> header
All AI endpoints require valid token
Optimistic UI Updates

Chats appear instantly with temporary negative IDs
Background resolver polls for real ID from server
Spinner shows until resolution completes
Auto-Title Generation

Triggered automatically after first message
Uses OpenAI to generate 6-word summary
Fallback to manual title if generation fails
Image Upload Flow

Select images with FilePicker
Upload to /api/ai/uploads (multipart/form-data)
Receive attachment IDs
Send message with attachmentIds array
AI analyzes images and responds
Research Mode

Toggle activates Tavily web search
AI searches before responding
Returns sources with title, snippet, URL
Sources clickable to open in browser
📦 DependenciesFlutter (pubspec.yaml)
yamldependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  file_picker: ^8.0.0
  url_launcher: ^6.2.0
  flutter_markdown: ^0.7.4
  http_parser: ^4.0.2Node.js (package.json)
json{
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "openai": "^4.20.0",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5",
    "axios": "^1.6.0"
  }
}⚠️ Known Limitations
No pagination UI - Message pagination endpoint exists but not implemented in UI
No message editing - Can't edit sent messages
No message deletion - Can only archive entire chats
Android emulator only - iOS networking may need adjustments
No rate limiting - Backend has no request throttling
No token refresh - JWT tokens expire without auto-refresh

🐛 Troubleshooting
401 Unauthorized Errors

Cause: Auth token not loaded or expired
Fix: Ensure ApiService.loadAuthToken() is called in main.dart

Images Not Displaying

Cause: Auth token issue in getAttachment
Fix: Verify authToken is used (not reading from SharedPreferences)

File Upload Fails (application/octet-stream)

Cause: MIME type not set correctly
Fix: Use http_parser to explicitly set content type

Backend Not Receiving Requests

Cause: Wrong base URL for emulator
Fix: Use 10.0.2.2:3000 for Android, localhost:3000 for iOS
