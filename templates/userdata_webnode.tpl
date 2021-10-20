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
    echo "<?php require_once('functions.php') ?>
      <html>
      <head>
        <title>Simple website</title>
      </head>
      <body>
      <h2>Posts</h2>
        <div>
          <?php
            echo get_entries();
          ?>
      </div>
      </body>
      </html>" > "$SRVPATH/index.php"
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
    echo "<?php
  require_once('config.php');

  function get_entries() {
    global \$conn;
    mysql_select_db('mysqldb');
    \$retval = '';
    \$query  = \"SELECT * FROM posts\";
    \$result = mysql_query(\$query, \$conn);
    if (! \$result) {
      die(\"Can not get data: \" . mysql_error());
    }

    while(\$row = mysql_fetch_array(\$result, MYSQL_ASSOC)) {
         \$retval .= \"<div>\";
         \$retval .= \"<h3>{\$row['title']}</h3>\";
         \$retval .= \"<div><span>{\$row['entry']}</span></div>\";
         \$retval .= \"</div>\";
    }
    
    mysql_close(\$conn);
    return \$retval;
  }
?>" > "$SRVPATH/functions.php"
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
        STATEMENT='INSERT INTO posts (id, title, entry) VALUES (1, "Jan B&ouml;hmermann", "hoffentlich gehen facebook, instagram und whatsapp nie wieder an"), (2, "Micky Beisenherz", "Wie sch&ouml;n das w&auml;re, wenn Social Media f&uuml;r 48 Stunden down w&auml;re und wir aus einer Art matrixartigem Schlaf erwachen und uns augenreibend fragen, was zur H&ouml;lle wir da gemeinsam eigentlich getan haben.<br />#whatsappdown #instadown"), (3, "GamerBrother", "Grad das erste Mal seit 2010 &uuml;ber SMS kommuniziert"), (4, "Kaufland", "#whatsappdown und #facebookdown. Wir haben &uuml;brigens auch Kerzen im Sortiment. F&uuml;r alle F&auml;lle."), (5, "Erik Fl&uuml;gge", "Ein einziger Konzern ist down und die halbe Welt ist kommunikativ lahmgelegt...<br />Fr&uuml;her hat man ja Monopole zerschlagen. Fr&uuml;her.<br />#facebookdown, #instagramdown, #whatsappdown"), (6, "Philip Steuer", "Stellt euch mal vor, alle Social Networks w&uuml;rden jeden Tag um 18 Uhr dicht machen & erst morgens um 8 Uhr wieder &ouml;ffnen. Sonntags komplett zu.<br />W&uuml;rde es die Mental Health positiv beeinflussen?<br />Oder eher negativ, weil man sich mit sich selbst besch&auml;ftigt?<br />#facebookdown")'
        mysql -u "$DB_USER" -p"$DB_PASS" -e "$STATEMENT" -h "$DB_FQDN" --database=mysqldb
    fi
else
    echo "Table not exists ..."
    STATEMENT="CREATE TABLE posts ( id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, title varchar(255) NOT NULL, entry varchar(255) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1"
    mysql -u "$DB_USER" -p"$DB_PASS" -e "$STATEMENT" -h "$DB_FQDN" --database=mysqldb
    STATEMENT='INSERT INTO posts (id, title, entry) VALUES (1, "Jan B&ouml;hmermann", "hoffentlich gehen facebook, instagram und whatsapp nie wieder an"), (2, "Micky Beisenherz", "Wie sch&ouml;n das w&auml;re, wenn Social Media f&uuml;r 48 Stunden down w&auml;re und wir aus einer Art matrixartigem Schlaf erwachen und uns augenreibend fragen, was zur H&ouml;lle wir da gemeinsam eigentlich getan haben.<br />#whatsappdown #instadown"), (3, "GamerBrother", "Grad das erste Mal seit 2010 &uuml;ber SMS kommuniziert"), (4, "Kaufland", "#whatsappdown und #facebookdown. Wir haben &uuml;brigens auch Kerzen im Sortiment. F&uuml;r alle F&auml;lle."), (5, "Erik Fl&uuml;gge", "Ein einziger Konzern ist down und die halbe Welt ist kommunikativ lahmgelegt...<br />Fr&uuml;her hat man ja Monopole zerschlagen. Fr&uuml;her.<br />#facebookdown, #instagramdown, #whatsappdown"), (6, "Philip Steuer", "Stellt euch mal vor, alle Social Networks w&uuml;rden jeden Tag um 18 Uhr dicht machen & erst morgens um 8 Uhr wieder &ouml;ffnen. Sonntags komplett zu.<br />W&uuml;rde es die Mental Health positiv beeinflussen?<br />Oder eher negativ, weil man sich mit sich selbst besch&auml;ftigt?<br />#facebookdown")'
    mysql -u "$DB_USER" -p"$DB_PASS" -e "$STATEMENT" -h "$DB_FQDN" --database=mysqldb
fi

chown -R apache:apache $SRVPATH/*
systemctl restart httpd