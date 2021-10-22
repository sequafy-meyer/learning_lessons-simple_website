{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessSSMparameterStore",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:*:${account_id}:parameter/webserver/*"
    },
    {
      "Sid": "GetSecretsManagerValue",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:*:${account_id}:secret:db/credentials*"
    },
    {
      "Sid": "GetDecryptionKeyAndListAllOtherSecrets",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ConnectViaSSM",
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession",
        "ssm:TerminateSession",
        "ssm:ResumeSession",
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowAccessToContent",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${bucket_name}/*"
    }
  ]
}