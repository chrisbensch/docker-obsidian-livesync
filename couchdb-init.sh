#!/bin/bash

# Check if CouchDB is running first
if ! curl -s "http://localhost:5984" > /dev/null; then
    echo "Error: CouchDB is not running"
    exit 1
fi

# Check if obsidiandb exists
DB_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "http://admin:password@localhost:5984/obsidiandb")

case $DB_CHECK in
    200)
        echo "Database 'obsidiandb' already exists. Exiting..."
        exit 0
        ;;
    401)
        echo "Error: Unauthorized. Check admin credentials."
        exit 1
        ;;
    404)
        echo "Database not found. Starting setup..."
        ;;
    *)
        echo "Error: Unexpected response (HTTP $DB_CHECK)"
        exit 1
        ;;
esac

# Initialize single node setup
curl -X POST "http://admin:password@localhost:5984/_cluster_setup" \
     -H "Content-Type: application/json" \
     -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"password", "port": 5984, "node_count": "1", "single_node": true}'

# Finish the cluster setup
curl -X POST "http://admin:password@localhost:5984/_cluster_setup" \
     -H "Content-Type: application/json" \
     -d '{"action": "finish_cluster"}'

# Create a non-partitioned database
curl -X PUT http://admin:password@localhost:5984/obsidiandb \
     -H "Content-Type: application/json" -d '{ "partitioned": false }'

# Apply configuration settings
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/chttpd/require_valid_user -d '"true"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/chttpd_auth/require_valid_user -d '"true"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/httpd/WWW-Authenticate -d '"Basic realm=\"couchdb\""'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/httpd/enable_cors -d '"true"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/chttpd/enable_cors -d '"true"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/chttpd/max_http_request_size -d '"4294967296"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/couchdb/max_document_size -d '"50000000"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/cors/credentials -d '"true"'
curl -X PUT http://admin:password@localhost:5984/_node/_local/_config/cors/origins -d '"app://obsidian.md,capacitor://localhost,http://localhost"'

echo "Single-node CouchDB setup with configurations completed."
