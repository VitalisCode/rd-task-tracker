# rd-api-policy.hcl
# Principle of least privilege — only read, never write or delete

path "secret/data/rd-task-tracker/api" {
  capabilities = ["read"]
}

# Allow reading metadata (for secret versioning)
path "secret/metadata/rd-task-tracker/api" {
  capabilities = ["read", "list"]
}

# Explicitly deny everything else
path "secret/*" {
  capabilities = ["deny"]
}

path "sys/*" {
  capabilities = ["deny"]
}