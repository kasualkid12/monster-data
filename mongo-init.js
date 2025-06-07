// Create the database and collection
db = db.getSiblingDB(process.env.MONGO_DB_NAME || 'dnd_monster_data');
db.createCollection('creatures');

// Create indexes for better query performance
db.creatures.createIndex({ name: 1 });
db.creatures.createIndex({ type: 1 });
db.creatures.createIndex({ challenge_rating: 1 });
