{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowAccessToContent",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${bucket_name}/*",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:ec2:${region}:${account_id}:instance/*"
        }
      }
    }
  ]
}