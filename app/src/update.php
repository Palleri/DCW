<?php

if (isset($_GET['update']) )
{

#ob_start();
#$command=passthru('/usr/bin/python3 /app/test.py --container '. $_POST['update'] .'');

$create_file_upgrade = fopen("/var/www/upgrade.txt", "w") or die("Unable to open file!");
  $txt_upgrade = $_GET['update'];
  fwrite($create_file_upgrade, $txt_upgrade);
  if(file_exists("/var/www/upgrade.txt")){
    while(file_exists("/var/www/upgrade.txt")){
      
      if(file_exists("/var/www/upgrade.txt")){
      }else{
        $url = $_SERVER['REQUEST_URI'];
        $url_stripped = str_replace("update.php", "index.php", $url);
        sleep(3);
        echo "<script>window.location = '$url_stripped'</script>";
      }
    }
  }


/*
}else {
        echo "Normal update script";
/*  $create_file_update = fopen("/var/www/update.txt", "w") or die("Unable to open file!");
  $txt = '1';
  fwrite($create_file_update, $txt);
  $read_file = file_get_contents('/var/www/update.txt');
  if($read_file == '1'){
    while($read_file == '1'){
      $read_file = file_get_contents('/var/www/update.txt');
      if($read_file == '1'){
      }else{
        $url = $_SERVER['REQUEST_URI'];
        $url_stripped = str_replace("update.php", "index.php", $url);
        sleep(3);
        echo "<script>window.location = '$url_stripped'</script>";
      }
    }
  }

 */
}
?>