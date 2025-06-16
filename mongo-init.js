// Create admin user
db = db.getSiblingDB('admin');
db.createUser({
  user: process.env.MONGO_INITDB_ROOT_USERNAME || 'admin',
  pwd: process.env.MONGO_INITDB_ROOT_PASSWORD || 'adminpassword',
  roles: [{ role: 'root', db: 'admin' }],
});

// Create the application database and collection
db = db.getSiblingDB(process.env.MONGO_INITDB_DATABASE || 'dnd_db');
db.createCollection('creatures');

// Create indexes for better query performance
db.creatures.createIndex({ name: 1 });
db.creatures.createIndex({ type: 1 });
db.creatures.createIndex({ challenge_rating: 1 });
