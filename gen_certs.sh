#!/bin/bash

# CREATE THE PRIVATE KEY FOR OUR CUSTOM CA
openssl genrsa -out certs/ca.key 2048

# GENERATE A CA CERT WITH THE PRIVATE KEY
openssl req -x509 -new -nodes -key certs/ca.key -days 100000 -out certs/ca.crt -subj "/CN=admission_ca"  

# CREATE SERVER CONFIGURATION FILE. CN = webhook.default.svc (FQDN)
cat >certs/server.conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no
[req_distinguished_name]
CN = webhook.default.svc
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = webhook.default.svc
EOF

# CREATE THE PRIVATE KEY FOR OUR SERVER
openssl genrsa -out certs/server.key 2048

# CREATE A CSR FROM THE CONFIGURATION FILE AND OUR PRIVATE KEY
openssl req -new -key certs/server.key -out certs/server.csr -config certs/server.conf

# CREATE THE CERT SIGNING THE CSR WITH THE CA CREATED BEFORE
openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -days 100000 -extensions v3_req -extfile certs/server.conf

# CREATE PKCS12 FILE
openssl pkcs12 -export -in certs/server.crt -inkey certs/server.key -out certs/server.p12 -name webhook.default.svc

# COPY PKCS12 FILE TO RESOURCES
cp certs/server.p12 src/main/resources

# CREATE VALIDATING WEBHOOK YAML USING CA CERT
cat > kubernetes/validating-webhook.yaml <<EOF
kind: ValidatingWebhookConfiguration
apiVersion: admissionregistration.k8s.io/v1
metadata:
  name: validating-webhook
webhooks:
  - name: validating-webhook.bb.com
    namespaceSelector:
      matchExpressions:
      - key: openpolicyagent.org/webhook
        operator: NotIn
        values:
        - ignore
    rules:
      - operations: ["CREATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["*"]
    clientConfig:
      caBundle: $(cat certs/ca.crt | base64 | tr -d '\n')
      service:
        namespace: default
        name: webhook
        path: "/"
    sideEffects: None
    admissionReviewVersions: ["v1"]
EOF