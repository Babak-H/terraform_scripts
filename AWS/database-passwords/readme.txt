Solution 1:

we can set the username and password that are terraform variables as local Environment Variables:
    export TF_VAR_username = "root"
    export TF_VAR_password = "devops123"

and when running terraform apply, they will be automatically picked up.
===================================================
Solution 2:

use aws KMS to create encryption key: "symmetric" and "encrypt and decrypt"
user that uses this key should be same username that is accessing terraform scripts
now encrypt the db-creds.yml file:
    aws kms encrypt --key-id <KEY_ID> --region us-east-1 --plaintext fileb://db-creds.yml --output text --query CiphertextBlob > db-creds.yml.encrypted

the result is an safe encrypted file, we can decrypt and use it (as written in rds.tf file)


