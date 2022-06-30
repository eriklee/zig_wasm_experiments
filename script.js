var memory = new WebAssembly.Memory({
  initial: 40, /* pages */
  maximum: 40, /* pages */
});

function console_log_ex(location, size) {
  var buffer = new Uint8Array(memory.buffer, location, size);
  var decoder = new TextDecoder();
  var string = decoder.decode(buffer);
  console.log(string);
}

var importObject = {
  env: {
    consoleLogEx: (location, size) => console_log_ex(location, size),
    memory: memory,
  },
};

WebAssembly.instantiateStreaming(fetch("checkerboard.wasm"), importObject).then(
  (result) => {
    const wasmMemoryArray = new Uint8Array(memory.buffer);

    const canvas = document.getElementById("checkerboard");
    const context = canvas.getContext("2d");
    const imageData = context.createImageData(canvas.width, canvas.height);
    context.clearRect(0, 0, canvas.width, canvas.height);

    /*
    const getDarkValue = () => {
      return Math.floor(Math.random() * 100);
    };
    const getLightValue = () => {
      return Math.floor(Math.random() * 127) + 127;
    };
    */

    const setStyle = () => {
      const sty_s = document.getElementById("Style").value;
      var sty = 2;
      if (sty_s == "rect") sty = 0;
      else if (sty_s == "line") sty = 1;
      result.instance.exports.setStyle(sty);
    };

    const drawScreen = () => {
      const screen_height = 240;
      const screen_width = 320;

      const lc = parseInt(document.getElementById("line_count").value);
      const angle = parseInt(document.getElementById("angle").value);
      const ll = parseInt(document.getElementById("line_length").value);
      const t = Date.now();

      result.instance.exports.drawScreen(lc, angle, ll, t);

      const bufferOffset = result.instance.exports.getScreenBufferPointer();
      const imageDataArray = wasmMemoryArray.slice(
        bufferOffset,
        bufferOffset + screen_height * screen_width * 4,
      );
      imageData.data.set(imageDataArray);

      context.clearRect(0, 0, canvas.width, canvas.height);
      context.putImageData(imageData, 0, 0);
    };

    drawScreen();
    console.log(memory.buffer);
    document.getElementById("make_image").addEventListener("click", drawScreen);
    document.getElementById("line_length").addEventListener(
      "change",
      drawScreen,
    );
    document.getElementById("angle").addEventListener("change", drawScreen);
    document.getElementById("line_count").addEventListener(
      "change",
      drawScreen,
    );

/*
    document.getElementById("Style").addEventListener("change", setStyle);
    setInterval( () => {
    drawScreen();
  }, 16);
function getCursorPosition(canvas, event) {
    const rect = canvas.getBoundingClientRect()
    const x = event.clientX - rect.left
    const y = event.clientY - rect.top
    console.log("x: " + x + " y: " + y)
}

const canvas = document.querySelector('canvas')
canvas.addEventListener('mousedown', function(e) {
    getCursorPosition(canvas, e)
})
  */
  },
);
