# #!/bin/bash
# # Rotate the API secret key without redeploying anything

# echo "Rotating API secrets in Vault..."

# # Write a new version of the secret
# vault kv put secret/rd-task-tracker/api \
#   secret_key="rotated-key-$(openssl rand -hex 32)" \
#   db_password="rotated-pg-$(openssl rand -hex 16)" \
#   jwt_secret="rotated-jwt-$(openssl rand -hex 32)"

# echo "New secret version written."
# echo "Vault agent sidecars will pick up the new values within TTL (1h)"
# echo "No pod restart needed — Vault agent handles renewal automatically"

# # Verify new version
# vault kv metadata get secret/rd-task-tracker/api
