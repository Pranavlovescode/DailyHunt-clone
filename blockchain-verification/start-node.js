const { spawn } = require('child_process');
const path = require('path');

// Configuration
const PORT = process.env.PORT || 8545;
const NETWORKID = process.env.NETWORKID || 31337;

console.log('\x1b[36m%s\x1b[0m', '🚀 Starting Hardhat node...');
console.log('\x1b[36m%s\x1b[0m', `🌐 Network ID: ${NETWORKID}`);
console.log('\x1b[36m%s\x1b[0m', `🔌 RPC URL: http://127.0.0.1:${PORT}`);

// Start the Hardhat node
const hardhat = spawn('npx', ['hardhat', 'node', '--hostname', '0.0.0.0', '--port', PORT.toString()], {
  cwd: __dirname,
  stdio: 'pipe' // Pipe the output so we can format it
});

// Format the output with timestamps
hardhat.stdout.on('data', (data) => {
  const timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
  const lines = data.toString().trim().split('\n');
  
  for (const line of lines) {
    if (line.trim()) {
      console.log(`\x1b[90m[${timestamp}]\x1b[0m ${line}`);
    }
  }
});

hardhat.stderr.on('data', (data) => {
  const timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
  const lines = data.toString().trim().split('\n');
  
  for (const line of lines) {
    if (line.trim()) {
      console.log(`\x1b[31m[${timestamp} ERROR]\x1b[0m ${line}`);
    }
  }
});

// Deploy the contract once the node is running
setTimeout(() => {
  console.log('\x1b[33m%s\x1b[0m', '\n🔄 Deploying NewsVerifier contract...');
  
  const deploy = spawn('npx', ['hardhat', 'run', '--network', 'localhost', 'scripts/deploy.js'], {
    cwd: __dirname,
    stdio: 'pipe'
  });

  deploy.stdout.on('data', (data) => {
    console.log('\x1b[32m%s\x1b[0m', data.toString().trim());
  });

  deploy.stderr.on('data', (data) => {
    console.log('\x1b[31m%s\x1b[0m', data.toString().trim());
  });

  deploy.on('exit', (code) => {
    if (code !== 0) {
      console.log('\x1b[31m%s\x1b[0m', '❌ Contract deployment failed');
    } else {
      console.log('\x1b[32m%s\x1b[0m', '✅ Contract deployed successfully');
    }
  });
}, 5000);

// Handle process termination
process.on('SIGINT', () => {
  console.log('\x1b[33m%s\x1b[0m', '\n🛑 Shutting down Hardhat node...');
  hardhat.kill('SIGINT');
  process.exit();
});

process.on('SIGTERM', () => {
  console.log('\x1b[33m%s\x1b[0m', '\n🛑 Shutting down Hardhat node...');
  hardhat.kill('SIGTERM');
  process.exit();
});