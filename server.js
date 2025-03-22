const http = require("http");
const mysql = require("mysql2"); // Import mysql2 package
const hostname = "0.0.0.0"; // Listen on all interfaces
const port = 3000; // Port to listen on
const dotenv = require("dotenv");
dotenv.config(); // Load environment variables from .env file

const db = mysql.createConnection({
  host: process.env.DB_HOST, // Use the environment variable from .env
  user: process.env.DB_USER, // Use app_user from .env
  password: process.env.DB_PASSWORD, // Use app_user password from .env
  database: process.env.DB_NAME, // Use app_db from .env
  port: process.env.DB_PORT, // Use the port from .env
});

// Connect to the MySQL database
db.connect((err) => {
  if (err) {
    console.error("Error connecting to MySQL database: ", err);
    return;
  }
  console.log("Connected to MySQL database!");
});

http
  .createServer((req, res) => {
    // Handle /health route
    if (req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "healthy", uptime: process.uptime() }));
    }

    // Handle /users route
    else if (req.url === "/users") {
      // Query the users table
      db.query("SELECT * FROM users", (err, results) => {
        if (err) {
          console.error("Error fetching users from database:", err);
          res.writeHead(500, { "Content-Type": "text/plain" });
          res.end("Internal Server Error");
          return;
        }

        // Respond with the user data
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify(results));
      });
    }

    // Default route
    else {
      res.writeHead(200, { "Content-Type": "text/plain" });
      res.end("Node app is running!");
    }
  })
  .listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`);
  });
