# Use the official MongoDB image from Docker Hub
FROM mongo:latest

# Copy your JSON file to the container
COPY monsters.json /monsters.json

# Run the MongoDB and import the JSON file
CMD mongoimport --host mongodb --db gh_database --collection gh_collection --file /monsters.json --jsonArray
