<html>
    <head>
    <title>Docker Updates</title>
    <link rel="stylesheet" href="style.css">
    <link rel="icon" href="favico.jpeg">

    <script src="jquery.js"></script>
<script>

$(document).on("click", "button", function(){   
    $.get("update.php", function(data){
        $(".loading-container hide").html(data);
        $(".content").html(data);
    });       
});


$(document).on({
    ajaxStart: function(){
        $(".loading-container").removeClass("hide");
        $(".loading").removeClass("hide");
        $("#loading-text").removeClass("hide");
        $(".content").addClass("hide");
    },
    ajaxStop: function(){ 
        $(".loading-container").addClass("hide");
        $(".loading").addClass("hide");
        $("#loading-text").addClass("hide");
        $(".content").RemoveClass("hide");
        location.reload(true);
    }    
});
</script>

    </head>
<body>
<?php
?>
<div class="loading-container hide">
      <div class="loading"></div>
      <div id="loading-text">loading</div>
      </div>
<div class="content">

<h1><a href=index.php>Dockcheck</a></h1>


 
<header>
<h1><button type="button">Check for updates</button></h1>
  <!-- <h1><div id="updates" href=index.php?update>Check for updates</a></h1></div -->
</header>
<div class="row">
  <div class="column">
    <table>
      <tr>
        <th class="latest">Containers on latest version:</th>
        <th></th>
      </tr>
      <?php


$conn = pg_connect("host=localhost port=5432 dbname=postgres user=postgres");
if (!$conn) {
    echo "An error occurred.\n";
    exit;
}

$result = pg_query($conn, "SELECT * FROM containers WHERE latest='true'");
if (!$result) {
    echo "skit hände.\n";
    exit;
}





while ( $data  = pg_fetch_array($result))
{
    echo '<tr>';
    echo '<td>'. $data["name"] .'</td>';
    echo '<td>'. $data["host"] .'</td>';
    echo '</tr>';
}



        ?>

    </table>
  </div>
  <div class="column">
    <table>
      <tr>
        <th class="update">Containers with updates available:</th>
        <th></th>
      </tr>
      <?php


$conn = pg_connect("host=localhost port=5432 dbname=postgres user=postgres");
if (!$conn) {
    echo "An error occurred.\n";
    exit;
}

$result = pg_query($conn, "SELECT * FROM containers WHERE new='true'");
if (!$result) {
    echo "skit hände.\n";
    exit;
}



while ( $data  = pg_fetch_array($result))
{
    echo '<tr>';
    echo '<td>'. $data["name"] .'</td>';
    echo '<td>'. $data["host"] .'</td>';
    echo '</tr>';
}



        ?>

    </table>

  </div>

</div>
<div class="row">
<div class="error">
    <hr>
    <table>
      <tr>
        <th class="error">Containers with errors, wont get updated:</th>
        <th></th>
        
      </tr>
      <?php


$conn = pg_connect("host=localhost port=5432 dbname=postgres user=postgres");
if (!$conn) {
  echo "An error occurred.\n";
  exit;
}

$result = pg_query($conn, "SELECT * FROM containers WHERE error='true'");
if (!$result) {
  echo "skit hände.\n";
  exit;
}

while ( $data  = pg_fetch_array($result))
{
  echo '<tr>';
  echo '<td>'. $data["name"] .'</td>';
  echo '<td>'. $data["host"] .'</td>';
  echo '</tr>';
}



        ?>

    </table>

  </div>
</div>

</body>
</html>