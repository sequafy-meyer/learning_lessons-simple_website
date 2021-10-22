#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
REGION=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//'`
SRVPATH="/srv/data"
MOUNT_POINT=`aws --region $REGION ssm get-parameter --name /webserver/efs/www | python2 -c 'import sys, json; print json.load(sys.stdin)["Parameter"]["Value"]'`
DB_USER=`aws --region $REGION secretsmanager get-secret-value --secret-id db/credentials | python2 -c "import sys, json; print json.load(sys.stdin)['SecretString']" | python2 -c "import sys, json; print json.load(sys.stdin)['username']"`
DB_PASS=`aws --region $REGION secretsmanager get-secret-value --secret-id db/credentials | python2 -c "import sys, json; print json.load(sys.stdin)['SecretString']" | python2 -c "import sys, json; print json.load(sys.stdin)['password']"`
DB_FQDN=`aws --region $REGION ssm get-parameter --name /webserver/db/fqdn | python2 -c 'import sys, json; print json.load(sys.stdin)["Parameter"]["Value"]'`

# mount EFS volume https://docs.aws.amazon.com/efs/latest/ug/gs-step-three-connect-to-ec2-instance.html
echo 'Mount EFS file system ...'
mkdir -p $SRVPATH
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $MOUNT_POINT:/ $SRVPATH

# create fstab entry to ensure automount on reboots https://docs.aws.amazon.com/efs/latest/ug/mount-fs-auto-mount-onreboot.html#mount-fs-auto-mount-on-creation
echo 'Create fstab ...'
echo '$MOUNT_POINT:/ $SRVPATH nfs4 defaults,vers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0' >> /etc/fstab

echo 'Create files ...'
if [ ! -f "$SRVPATH/index.php" ]; then
  aws s3 cp s3://${bucket_name}/index.php $SRVPATH/index.php
fi

if [ ! -f "$SRVPATH/config.php" ]; then
    echo "<?php
      // connect to database
      \$conn = mysql_connect('$DB_FQDN', '$DB_USER', '$DB_PASS');

      if (! \$conn) {
        die(\"Error connecting to database: \" . mysql_error());
      }
?>" > "$SRVPATH/config.php"
fi

if [ ! -f "$SRVPATH/functions.php" ]; then
  aws s3 cp s3://${bucket_name}/functions.php $SRVPATH/functions.php
fi

# Do some database magic
echo 'Database magic ...'
if [[ $(mysql -u "$DB_USER" -p"$DB_PASS" -e 'SHOW TABLES LIKE "posts"' -h "$DB_FQDN" --database=mysqldb) ]]
then
    echo "Table exists ..."

    # Check if table has records    
    if [[ $(mysql -u "$DB_USER" -p"$DB_PASS" -e 'SELECT 1 FROM posts LIMIT 1' -h "$DB_FQDN" --database=mysqldb) ]]
    then
        echo "Table has records ..."
    else
        echo "Table is empty ..."
        STATEMENT='INSERT INTO posts (id, title, entry) VALUES (1, "Steve Jobs", "Let&apos;s go invent tomorrow instead of worrying about what happened yesterday."), (2, "Stewart Brand", "Once a new technology rolls over you, if you&apos;re not part of the steamroller, you&apos;re part of the road."), (3, "Christian Lous Lange", "Technology is a useful servant but a dangerous master."), (4, "Billy Cox", "Technology should improve your life… not become your life."), (5, "Steve Jobs", "Technology is nothing. What&apos;s important is that you have a faith in people, that they&apos;re basically good and smart, and if you give them tools, they&apos;ll do wonderful things with them."), (6, "Arthur C. Clarke", "Any sufficiently advanced technology is equivalent to magic."), (7, "Douglas Adams", "Technology is a word that describes something that doesn&apos;t work yet.")'
        mysql -u "$DB_USER" -p"$DB_PASS" -e "$STATEMENT" -h "$DB_FQDN" --database=mysqldb
    fi
else
    echo "Table not exists ..."
    STATEMENT="CREATE TABLE posts ( id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, title varchar(255) NOT NULL, entry varchar(255) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1"
    mysql -u "$DB_USER" -p"$DB_PASS" -e "$STATEMENT" -h "$DB_FQDN" --database=mysqldb
    STATEMENT='INSERT INTO posts (id, title, entry) VALUES (1, "Steve Jobs", "Let&apos;s go invent tomorrow instead of worrying about what happened yesterday."), (2, "Stewart Brand", "Once a new technology rolls over you, if you&apos;re not part of the steamroller, you&apos;re part of the road."), (3, "Christian Lous Lange", "Technology is a useful servant but a dangerous master."), (4, "Billy Cox", "Technology should improve your life… not become your life."), (5, "Steve Jobs", "Technology is nothing. What&apos;s important is that you have a faith in people, that they&apos;re basically good and smart, and if you give them tools, they&apos;ll do wonderful things with them."), (6, "Arthur C. Clarke", "Any sufficiently advanced technology is equivalent to magic."), (7, "Douglas Adams", "Technology is a word that describes something that doesn&apos;t work yet.")'
    mysql -u "$DB_USER" -p"$DB_PASS" -e "$STATEMENT" -h "$DB_FQDN" --database=mysqldb
fi

chown -R apache:apache $SRVPATH/*
systemctl restart httpd