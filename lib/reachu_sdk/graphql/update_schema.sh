#!/bin/bash
# Script to update ReachU GraphQL schema

API_KEY="V9GYBXH-99DMHGR-PC1M23P-YNSD7AC"
ENDPOINT="https://graph-ql.reachu.io/"
OUTPUT="$(dirname "$0")/schema.json"

curl -X POST $ENDPOINT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  --data '{"query":"query IntrospectionQuery { __schema { queryType { name } mutationType { name } subscriptionType { name } types { ...FullType } directives { name description locations args { ...InputValue } } } } fragment FullType on __Type { kind name description fields(includeDeprecated: true) { name description args { ...InputValue } type { ...TypeRef } isDeprecated deprecationReason } inputFields { ...InputValue } interfaces { ...TypeRef } enumValues(includeDeprecated: true) { name description isDeprecated deprecationReason } possibleTypes { ...TypeRef } } fragment InputValue on __InputValue { name description type { ...TypeRef } defaultValue } fragment TypeRef on __Type { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name } } } } } } } }"}' \
  -o "$OUTPUT"

echo "Schema actualizado en $OUTPUT" 