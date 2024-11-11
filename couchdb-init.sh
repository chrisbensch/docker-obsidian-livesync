#!/bin/bash
sleep 5
# Wait for CouchDB to start
until curl -s -f -u obsidian_user:password http://localhost:5984/_up; do
  echo "Waiting for CouchDB to start..."
  sleep 2
done

echo "CouchDB started, proceeding with database check..."

# Function to check if the database already exists

database_exists() {
  curl -s -f -u obsidian_user:password curl -s -f -u obsidian_user:password http://localhost:5984/obsidiandb > /dev/null
}

# Check if the database exists
if database_exists; then
  echo "Database 'obsidiandb' already exists. Skipping initialization."
  exit 0
fi

echo "Database 'obsidiandb' does not exist..."
echo "Proceeding with single-node setup..."

# Set up CouchDB as a single node
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/obsidian_users/obsidian_user -d '"password"'

# Enable clustered setup with a single node
curl -X PUT http://obsidian_user:password@localhost:5984/_cluster_setup -H "Content-Type: application/json" -d '{
  "action": "enable_single_node",
  "username": "obsidian_user",
  "password": "password"
}'

# Finalize single-node setup
curl -X POST http://obsidian_user:password@localhost:5984/_cluster_setup -H "Content-Type: application/json" -d '{
  "action": "finish_cluster"
}'

# Create a non-partitioned database
curl -X PUT http://obsidian_user:password@localhost:5984/obsidiandb -H "Content-Type: application/json" -d '{
  "partitioned": false
}'

# Apply configuration settings
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/chttpd/require_valid_user -d '"true"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/chttpd_auth/require_valid_user -d '"true"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/httpd/WWW-Authenticate -d '"Basic realm=\"couchdb\""'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/httpd/enable_cors -d '"true"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/chttpd/enable_cors -d '"true"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/chttpd/max_http_request_size -d '"4294967296"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/couchdb/max_document_size -d '"50000000"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/cors/credentials -d '"true"'
curl -X PUT http://obsidian_user:password@localhost:5984/_node/_local/_config/cors/origins -d '"app://obsidian.md,capacitor://localhost,http://localhost"'

echo "Single-node CouchDB setup with configurations completed."
