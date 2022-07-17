<?php
// -------------------------------------------------------
// Zoneminder camera wall display using Zoneminder API
//
// Display parameters :
//   ratio  - Camera ratio (default=1.77)
//   column - Number of camera per line
//   width  - Width of the wall in pixels (default=1980px)
//   zoom   - Width of a zoomed image in pixels (default=1080px)
//
// Camera selection :
//   index  - Index of first cam to display in ZM sequence list
//   maxcam - Maximum number of cameras to display
//   cams   - ordered list of cams to display using ZM mid (exemple : 1-10-4-8-14-2)
//
// Revision history :
//   07/06/2017 - V1.0 - Creation by N. Bernaerts
//   14/07/2017 - V1.1 - Adapt to use cam-resize.php
//   02/09/2017 - V2.0 - Rewrite to get cam list and cam pictures from ZoneMinder API
//   10/11/2017 - V2.1 - Change refresh algo to unload server and optimize refresh rate
//   17/11/2017 - V2.2 - Remove network topology difference (internet or lan)
//   15/05/2018 - V2.3 - Add alert status
//   18/11/2018 - V2.4 - Add cams parameter to specify camera list to be displayed
//   22/01/2019 - V2.5 - Remove disabled cams from the wall
//   03/02/2020 - V3.0 - Switch the wall from table to grid
// -------------------------------------------------------

// zoneminder configuration
//require_once ("camera-config.inc");
header('refresh: 3600');
/*var_dump("<br>");
var_dump();
var_dump("</br>");*/
// initialisation
const access_token = "access_token";
const refresh_token = "refresh_token";
$zmHURL = (isset($_SERVER['HTTPS'])? "https://" : "http://").$_SERVER["HTTP_HOST"];

$arrCam       = Array ();
$arrDisplay   = Array ();
//$arrZMCookie  = Array ();
//$arrCamCookie = Array ();
$arrMonitor   = Array ();
$arrOrdered   = Array ();

// Parameter : Display ratio for cameras
$camRatio = 1.77;
if (isset($_GET["ratio"])) $camRatio = $_GET["ratio"];
// Parameter : Maximum number of cameras
$maxCam = 0;
if (isset($_GET["maxcam"])) $maxCam = $_GET["maxcam"];
// Parameter : Number of columns
$nbrColumn = 0;
if (isset($_GET["column"])) $nbrColumn = $_GET["column"];
// Parameter : Width of the wall (in pixels)
$wallWidth = 1920;
if (isset($_GET["width"])) $wallWidth = $_GET["width"];
// Parameter : Width of the zoomed picture (in pixels)
$zoomWidth = 1280;
if (isset($_GET["zoom"])) $zoomWidth = $_GET["zoom"];
// Parameter : Index of first cam on the wall (starts from 0)
$wallIndex = 0;
if (isset($_GET["index"])) $wallIndex = $_GET["index"];
// Parameter : List of cams to display
if (isset($_GET["cams"])) $lstCam = $_GET["cams"];

// login to zoneminder

$usr = $_GET['user'];
if(!$usr) //если не задан параметр
{
    $handle = file("/observer1", FILE_IGNORE_NEW_LINES);
}elseif($usr=="obs2"){
    $handle = file("/observer2", FILE_IGNORE_NEW_LINES);
}else{
    $handle = file("/observer1", FILE_IGNORE_NEW_LINES);
}

$access_token = $str = preg_replace('/^[ \t]*[\r\n]+/m', '', $handle[0]);
//var_dump("<br>".$access_token."</br>");
// get monitor list
$url = "https://localhost:443/zm/api/monitors.json?token=".$access_token;
$ch = curl_init();
curl_setopt ($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt ($ch, CURLOPT_URL, $url);
$json = curl_exec ($ch);

curl_close ($ch);


// convert json to array
$arrMonitor = json_decode ($json, true);

// if monitors list is provided, generate array of cams to be displayed
if (isset($lstCam))
{
        // loop thru candidates
        $arrCandidate = explode ("-", $lstCam);
        foreach ($arrCandidate as $idxCandidate)
        {
                // loop thru monitors to get their Id
                foreach ($arrMonitor["monitors"] as $idxMonitor => $monitor)
                {
                        // if monitor index is candidate, add it to the display list
                        if ($idxCandidate == $monitor["Monitor"]["Id"]) $arrDisplay[] = $idxMonitor;
                }
        }
}

// if no list provided, generate ordered list from start index and max number of cams
if (empty($arrDisplay))
{
        // sort monitor array in sequence order
        foreach ($arrMonitor["monitors"] as $idxMonitor => $monitor) $arrOrdered[$idxMonitor] = $monitor["Monitor"]["Sequence"];
        asort ($arrOrdered);
        // loop thru ordered monitors to add monitorr to the array of cams to be displayed
        $count = 0;

        foreach ($arrOrdered as $idxMonitor => $idxDisplay)
        {
                # check if monitor is enabled
                $monitor = $arrMonitor["monitors"][$idxMonitor];
                $enabled = $monitor["Monitor"]["Enabled"];
                // populate cams array according to camera status, start index and wall size
                if (($enabled == "1") && ($idxDisplay >= $wallIndex) && (($maxCam == 0) || ($count < $maxCam)))
                {
                        // add monitor to display list
                        $arrDisplay[] = $idxMonitor;
                    //var_dump($idxMonitor);
                        // increment counter
                        $count++;
                }
        }
}

// number of cameras to display
$nbrCam = count ($arrDisplay);

// if number of column not defined, set it according to total number of cams
if ($nbrColumn == 0) $nbrColumn = ceil (sqrt ($nbrCam));

// calculate number of rows
$nbrRow = ceil ($nbrCam / $nbrColumn);
$vwRow  = floor (100 / $nbrColumn / $camRatio);

// calculate font size according to number of columns
$fontSize = 0.8 * ((7 / 3) - ($nbrColumn / 6));

// create camera array from sorted array of cams to be displayed
$count = 0;

foreach ($arrDisplay as $idxDisplay => $idxMonitor)
{
    // increment counter
    $count++;
    // get monitor data
    $monitor = $arrMonitor["monitors"][$idxMonitor];
    $camWidth  = $monitor["Monitor"]["Width"];
    $camHeight = $monitor["Monitor"]["Height"];

    // calculate scale factor
    $sizeThumb  = $wallWidth / $nbrColumn;
    $scaleThumb = max (min (100, ceil (100 * $sizeThumb / $camWidth)), min (100, ceil (100 * $sizeThumb / $camHeight)));
    $scaleZoom  = min (100, ceil (100 * $zoomWidth / $camWidth));

    // add cam to array
    $arrCam[$idxDisplay]['id']       = $monitor["Monitor"]["Id"];
    $arrCam[$idxDisplay]['width']    = $camWidth;
    $arrCam[$idxDisplay]['height']   = $camHeight;
    $arrCam[$idxDisplay]['name']     = "<small>[" . $monitor["Monitor"]["Id"] . "]</small> " . $monitor["Monitor"]["Name"];
    $arrCam[$idxDisplay]['urlthumb'] = $zmHURL."/".$monitor["Monitor"]["Id"]."/"."?width=740px&height=480px&scale=50&mode=jpeg&maxfps=30&monitor=".$monitor["Monitor"]["Id"]."&token=".$access_token;
    $arrCam[$idxDisplay]['urlzoom'] = $zmHURL."/".$monitor["Monitor"]["Id"]."/"."?width=1280px&height=720px&scale=50&mode=jpeg&maxfps=30&monitor=".$monitor["Monitor"]["Id"]."&token=".$access_token;

    $arrCamCookie['cam'][$count] = $monitor["Monitor"]["Id"];

}
// save array in cookie (to be used by cam-status.php)
setcookie ('cams', serialize($arrCamCookie), 0);
?>

<!doctype html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title><?php echo (/*$strWallName .*/ " - " . $nbrCam . " cameras"); ?></title>
    <link href="./styles.css" rel="stylesheet">
    <style type="text/css">
    <?php
    echo ("span { font-size:" . $fontSize . "vw; }");
    echo (".gallery { display:grid; grid-template-columns:repeat(" . $nbrColumn . ", 1fr); grid-template-rows:repeat(" . $nbrRow . ", " . $vwRow . "vw); grid-gap:1px; }");
    ?>
    </style>
    <script src="./zoom.js"></script>
</head>

<body id="wall" onload="initialize()">
    <div id="container" hidden = "true" class="container" >
        <img id="liveFeed" onclick='onClickZoomOut(this)' class="liveFeed"
             alt="There seems to be a problem with the live feed..."/>
    </div>

    <div class="gallery">
        <?php
            // loop to declare cameras
            $idxCam = 1;
            foreach ($arrCam as $cam)
            {
                    // display current camera
                    echo ("<figure class='gallery_item'>");
                    echo ("<span id='span" . $idxCam . "' >" . $cam['name'] . "</span>");
                    echo ("<a id='imgUnit".$cam['id']."'  ><img onclick='onClickZoomIn(this)' class='gallery_img' id='cam" . $idxCam . "' src='" . $cam['urlthumb'] . "' zoom='" . $cam['urlzoom'] . "' ></a>");
                    echo ("</figure>");

                    // increment counters
                    $idxCam++;
            }
        ?>
    </div>

</body>

</html>


