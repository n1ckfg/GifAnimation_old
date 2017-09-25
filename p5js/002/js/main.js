"use strict";

var api = "https://api.giphy.com/v1/gifs/search?";
var apiKey = "dc6zaTOxFJmzC";
var query="rainbow";
var gif = [];
var anim = [];
var ready = false;

function setup() {
  createCanvas(960, 540);
  background(127);
  
  var url = api + "&api_key=" + apiKey + "&q=" + query;
  loadJSON(url, gotData);
}

function draw() {
  if (ready && mouseIsPressed) {
    anim.push(new Anim(mouseX, mouseY, gif[parseInt(random(gif.length))]));
  }

  for (var i=0; i<anim.length; i++) {
    anim[i].run();
  }
}

function gotData(data) {
  for (var i=0; i<data.data.length; i++) {
    var url = data.data[i].images.original.url.split("?")[0];
    console.log(url);
    gif.push(loadGif(url));
  }

  ready = true;
}

class Anim {

  constructor(_x, _y, _gif) {
    this.x = _x;
    this.y = _y;
    this.gif = _gif;
  }

  run() {
    imageMode(CENTER);
    push();
    translate(this.x, this.y);
    scale(0.2, 0.2);
    image(this.gif, 0, 0);
    pop();
  }

}
