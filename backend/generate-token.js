require('dotenv').config();
const jwt = require('jsonwebtoken');

const userId = process.argv[2] || 'CObq5jp8PUMh3hjYysssBX689mH2';
const token = jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '24h' });

console.log(`Token for ${userId}:`);
console.log(token);
