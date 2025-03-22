# Simple Node.js Project

A basic Node.js application with MySQL database integration and simple API endpoints.

## Features

- RESTful API with the following endpoints:
  - `/` - Default route showing the application is running
  - `/health` - Health check endpoint returning application status and uptime
  - `/users` - Returns all users from the MySQL database

## Prerequisites

- Node.js (v12 or higher)
- MySQL Server
- npm (Node Package Manager)

## Setup Instructions

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd Simple-NodeJs-Project
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Create a `.env` file in the project root with the following contents:

   ```
   DB_HOST=localhost
   DB_USER=app_user
   DB_PASSWORD=yourpassword
   DB_NAME=app_db
   ```

4. Set up your MySQL database:

   - Create a database named `app_db`
   - Create a user `app_user` with appropriate permissions
   - Create a `users` table in the database

5. Start the server:

   ```bash
   node server.js
   ```

6. The server will be running at `http://0.0.0.0:3311`

## API Documentation

### Default Route

- **URL**: `/`
- **Method**: GET
- **Response**: Text message indicating the application is running

### Health Check

- **URL**: `/health`
- **Method**: GET
- **Response**: JSON object containing status and uptime information
  ```json
  {
    "status": "healthy",
    "uptime": 123.45
  }
  ```

### Users List

- **URL**: `/users`
- **Method**: GET
- **Response**: JSON array of user objects from the database

## Dependencies

- http - Core Node.js HTTP module
- mysql2 - MySQL client for Node.js
- dotenv - Environment variable loader
