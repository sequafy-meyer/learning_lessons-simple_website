A simple two layer website setup with:
- Network
- Database
- Storage
- Webserver
- ELB

Create tfvars file and go for it.

Create DB secret in advance
aws secretsmanager create-secret --name "db/credentials" --description "MySQL server credentials" --secret-string '{"username": "dbruth", "password": "t0pS3cr3tP@ssw0rd"}'

...more content missing