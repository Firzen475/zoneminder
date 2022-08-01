function onClickZoomIn(obj) {
    console.log("onClickZoomIn");
    var elem = document.getElementById("liveFeed");
    var container = document.getElementById("container");
    container.hidden = false;
    elem.setAttribute("zoom",obj.src);
    var srcTmp = obj.getAttribute("zoom");
    //var srcTmp = obj.src;
    obj.src = "";
    elem.src = srcTmp;
    elem.alt = obj.id;
    updateStreamSize();
}

function onClickZoomOut(obj) {
    console.log("onClickZoomOut");
    var elem = document.getElementById(obj.alt);
    var container = document.getElementById("container");
    container.hidden = true;
    var srcTmp = obj.getAttribute("zoom");
    obj.src = "";
    elem.src = srcTmp;
}

function initialize() {
    // Create function to handle resize
    // Register for resize events and do initial layout
    window.onresize = updateStreamSize;
    updateStreamSize();
    //elem.src = "/zm/cgi-bin/nph-zms?width=640px&height=480px&scale=100&mode=jpeg&maxfps=30&monitor=3";
    /* Get the element you want displayed in fullscreen mode (a video in this example): */
    var element = document.documentElement;

    /* When the openFullscreen() function is executed, open the video in fullscreen.
    Note that we must include prefixes for different browsers, as they don't support the requestFullscreen method yet */
        if(element.requestFullScreen) {
            element.requestFullScreen();
        } else if(element.mozRequestFullScreen) {
            element.mozRequestFullScreen();
        } 
}

function updateStreamSize() {
    ASPECT_RATIO = 16/9;
    var container = document.getElementById("container");
    var elem = document.getElementById("liveFeed");
    var containWidth = container.clientWidth;
    var containHeight = container.clientHeight;
    var width = 0;
    var height = 0;
    var border = 0;

    if (containWidth > 0 && containHeight > 0 &&
        containWidth > border * 2 && containHeight > border * 2) {

        // Check for skewing of ratio
        if ((containWidth - border * 2) /
            (containHeight - border * 2) < ASPECT_RATIO) {

            width = containWidth - border * 2;
            height = width / ASPECT_RATIO
        } else {
            height = containHeight - border * 2;
            width = height * ASPECT_RATIO
        }
    }

    // Update image size
    elem.style.width = width+"px";
    elem.style.height = height+"px";
    elem.style.top = (containHeight - height) / 2+"px";
    //elem.style.bottom =((containHeight - height) / 2)/2+"px";
    //elem.style.right = ((containWidth - width) / 2)/2+"px";
    elem.style.left = (containWidth - width) / 2+"px";
}

function check_camera(){
    // total number of cams on the wall
    function sayHi() {
        var elem = document.getElementById("cam1");
        if(elem == null ) {
            window.location.reload();
        }
        let xhr = new XMLHttpRequest();
        xhr.open('POST', elem.src);
        xhr.timeout = 500; // time in milliseconds
        xhr.send();
        xhr.onload = function() {
            if (xhr.status != 200) { // анализируем HTTP-статус ответа, если статус не 200, то произошла ошибка
                window.location.reload();
            }
        };
    }
    let timerId = setInterval( sayHi, 60000);
}
