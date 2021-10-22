<?php
  require_once('config.php');

  function get_entries() {
    global $conn;
    mysql_select_db('mysqldb');
    $retval = '';
    $query  = "SELECT * FROM posts";
    $result = mysql_query($query, $conn);
    if (! $result) {
      die("Can not get data: " . mysql_error());
    }

    while($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
         $retval .= "<div>";
         $retval .= "<h3>{$row['title']}</h3>";
         $retval .= "<div><span>{$row['entry']}</span></div>";
         $retval .= "</div>";
    }
    
    mysql_close($conn);
    return $retval;
  }
?>