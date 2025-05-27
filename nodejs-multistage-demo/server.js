const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Checking health Endpoint

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'I am healthy or so it seems',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        enviornment: process.env.NODE.EN || 'development',
        version: '1.0.0'
    })
})

// Lets test some Sample Endpoints for fun
app.get('/api/users', (req, res) => {
  res.json([
    { id: 1, name: 'John Gotti', email: 'john@example.com', role: 'admin' },
    { id: 2, name: 'Mrs. Gotti', email: 'jane@example.com', role: 'user' },
    { id: 3, name: 'John Jr', email: 'jonjr@example.com', role: 'user' }
  ]);
});

app.get('/api/status', (req, res) => {
  res.json({
    service: 'nodejs-multistage-demo',
    status: 'running',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Node.js Multi-Stage Docker Demo API',
    version: '1.0.0',
    endpoints: [
      'GET /health - Health check',
      'GET /api/users - Get all users', 
      'GET /api/status - Service status'
    ]
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});