function rand_uint8() {
    return Math.floor(Math.random() * 255)
}

$(document).ready(function() {
    setInterval(function() {
        $("body").css("background", "rgb("+rand_uint8()+","+rand_uint8()+","+rand_uint8()+")");
    }, 1000);
});
