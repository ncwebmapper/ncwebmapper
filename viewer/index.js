
//Config parameters
var zoom = 6;
var timeI = times.length-1;

var varMin =  0.0;
var varMax = 25.0;

var map_position = 0;

//////////////////////////PARÁMETROS//////////////////////////

/* Actualiza la URL con los parámetros que deficnen el mapa a cargar */
function updateURL(){
    var myURL = location.protocol + '//' + location.host + location.pathname;
    document.location = myURL + "#map_position=" + timeI;
};

/* Leer parámetros URL con #
http://stackoverflow.com/questions/19491336/get-url-parameter-jquery-or-how-to-get-query-string-values-in-js */
var getUrlParameter = function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location),
        sURLVariables = sPageURL.split('#'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};

map_position = parseInt(getUrlParameter("map_position"));
if(!isNaN(map_position)){
  timeI = map_position;
}

////////////////////////////////////////////////////////

var hybridMutant;
var controlCoordinates;

var degrees2meters = function(lon,lat) {
 var x = lon * 20037508.343 / 180;
 var y = Math.log(Math.tan((90 + lat) * Math.PI / 360)) / (Math.PI / 180);
 y = y * 20037508.343 / 180;
 return [x, y]
}

// cursorx=lat; cursory=lon;z=zoom;
// cursorx=38.7283759182398; cursory=-0.19775390625000003;z=7;
// cursory=4686507.078270013; cursorx=8560.947168029787; z=8;
extractCoorZoom = function(latlng, z, functionValue, int){

  int = typeof int !== 'undefined' ? int : false;

  // Primero tenemos que sacar la lat, lon del ratón
  var meters = degrees2meters(latlng.lng, latlng.lat);
  var cursory = meters[1];
  var cursorx = meters[0];

  var w1x = -20037508.343;
  var w1y = -20037508.343;
  var w2x = 20037508.343;
  var w2y = 20037508.343;

  // tile size
  var dx = (w2x - w1x) / Math.pow(2, z);
  var dy = (w2y - w1y) / Math.pow(2, z);
  // tile x,y
  var tx = Math.floor((cursorx - w1x) / dx);
  var ty = Math.floor((cursory - w1y) / dy);
  // pixel x,y
  var px = Math.round((cursorx - tx * dx - w1x) / (dx/256.0));
  var py = 255 - Math.round((cursory - ty * dy - w1y) / (dy/256.0));
  // mirror ty
  ty = Math.pow(2, z) - 1 - ty;

  var value = null;
  mousemoveTile = function(value){
    if(value != undefined)
    {
      functionValue(parseInt(value*10)/10);
    }
  }
  var bounds={x:tx, y:ty, z:z, px:px, py:py};
  var url=getURL(bounds, mousemoveTile, int);

  return(value);
}

function downloadMarkerCSV(event){
  event.stopPropagation();
  downloadCSV(clickPopup.value);
}

//x = "20"; y = "12"
function downloadCSV(x){
  var request;
  var arrayBuffer;
  var bytes;
  var asciistring;

  // Copiado de https://stackoverflow.com/questions/13405129/javascript-create-and-save-file
  // Function to download data to a file
  function download(data, filename, type) {
     var file = new Blob([data], {type: type});
     if (window.navigator.msSaveOrOpenBlob) // IE10+
       window.navigator.msSaveOrOpenBlob(file, filename);
     else { // Others
       var a = document.createElement("a"),
       url = URL.createObjectURL(file);
       a.href = url;
       a.download = filename;
       document.body.appendChild(a);
       a.click();
       setTimeout(function() {
         document.body.removeChild(a);
         window.URL.revokeObjectURL(url); 
       }, 0); 
     }
  }

 onload = function (e) {
    arrayBuffer = request.responseText;
    bytes = new Uint8Array(arrayBuffer.length);
    // Walk through each character in the stream. 
    for (var fileidx = 0; fileidx < arrayBuffer.length; fileidx++) {
      bytes[fileidx] = arrayBuffer.charCodeAt(fileidx) & 0xff;
    } 

    var blob = new Blob([bytes], {type: 'application/zip'});
    //window.location.href = URL.createObjectURL(b);

    zip.createReader(new zip.BlobReader(blob), function(zipReader){
      zipReader.getEntries(function(entries){
        var filename = entries[0].filename;
        entries[0].getData(new zip.BlobWriter('text/plain'), function(data) {
          download(data, filename, 'text/plain');
        });
      });
    }, function(error) { 
      errorMessage = "Please, select a point with data";
      alert(errorMessage); 
    });
  }

  onerror = function (e) {
    // alert("Problema en la descarga del CSV.");
  }

  var request = new XMLHttpRequest();

  request.onerror = onerror;
  request.onload = onload;
  f1 = parseInt(x) % 10;
  f2 = parseInt(parseInt(x)/10) % 10;
  f3 = parseInt(parseInt(x)/100) % 10;
  url = "./csv/" + f3 + "/"  + f2 + "/" + f1 + "/" + x + ".zip";
  asynchronous = true;
  request.open('GET', url, asynchronous);
  request.overrideMimeType('text\/plain; charset=x-user-defined');
  request.send(null);  
}

function getURL(bounds, done, int) {

  done = typeof done !== 'undefined' ? done : null;
  int = typeof int !== 'undefined' ? int : false;

  var x = bounds.x;
  var y = bounds.y;
  var z = bounds.z;
  var px = bounds.px;
  var py = bounds.py;
  var qx, qy, qz;

  var request = new XMLHttpRequest();

  var error;
  var canvas = document.createElement('canvas');
  canvas.width  = 256;
  canvas.height = 256;
  var floatArray;

  onload = function (e) {
    if (request.status === 200) {
      var ctx = canvas.getContext("2d");
      var imgd = ctx.getImageData(0, 0, 256, 256);
      var pix = imgd.data;
      var arrayBuffer = request.response;
      var byteArray = new Uint8Array(arrayBuffer);
      var gunzip = new Zlib.Gunzip ( byteArray );
      var decompressed = gunzip.decompress ();
      var buffer = new ArrayBuffer(4);
      if(!int){
        var floatView = new Float32Array(buffer);
      }else{
       var floatView = new Uint32Array(buffer);
     }
     var charView = new Uint8Array(buffer);
     floatArray = [];

     var k, l;

     k = 0;
     for (var j = 0; j < 256; j++)
     {
       for (var i = 0; i < 256; i++)
       {
          if(z <= mapMaxZoom || int)//px != undefined)
          {
            l = k;
          }
          else
          {
            l = ( parseInt(qx * 256 / qz) + parseInt(i / qz)  + 256 * (  parseInt(qy * 256 / qz) + parseInt(j / qz) ) ) * 4;
          }

          // TODO Avoid this copy
          charView[0] = decompressed[l  ];
          charView[1] = decompressed[l+1];
          charView[2] = decompressed[l+2];
          charView[3] = decompressed[l+3];

          // TODO Remove this fix for Roberto's units
          if(!int)
          {
              floatView[0] = floatView[0] / 10.0;
          }

          floatArray[k/4] = floatView[0];

          if(isNaN(floatView[0]))
          {
            // Transparent
            pix[k+3] = 0;
          }
          else
          {
            // Scale
            l = parseInt((floatView[0] - varMin) / (varMax - varMin) * 255.0);

            if(l < 0)
            {
              l = 0;
            }
            if(l > 255)
            {
              l = 255;
            }

            l = 3 * l;
            pix[k  ] = palette[l  ];
            pix[k+1] = palette[l+1];
            pix[k+2] = palette[l+2];
            pix[k+3] = 255;

            // Transparent
            if(floatView[0] <= varMin)
            {
              pix[k+3] = 0;
            }
          }

          k += 4;
       }
     }

      ctx.putImageData(imgd, 0, 0);            
    }

    if(px == undefined){
      done(error, canvas);
    }else{
      if(pix != undefined){
          done(floatArray[px+256*py]);
      }
    }
  }
  onerror = function (e) {
    if(px == undefined){
      done(error, canvas);
    }else{
        done(undefined);
    }
  }
  request.onerror = onerror;
  request.onload = onload;
  if(!int){
    timeNow = parseInt(timeI)+1;
  }else{
    timeNow = 0;
  }
  url = './map/' + timeNow + '/' + z + '/' + x + '/' + y + '.bin.gz';

  if(z > mapMaxZoom && !int)
  {
    qz = Math.pow(2, z - mapMaxZoom );
    qx = x - parseInt( x  / qz ) * qz;
    qy = y - parseInt( y  / qz ) * qz;
    url = './map/' + timeNow + '/' + mapMaxZoom + '/' + parseInt( x / qz ) + '/' + parseInt( y  / qz ) + '.bin.gz';
  }
  else
  {
    qz = 1;
    qx = x;
    qy = y;
  }

  asynchronous = true;
  request.open('GET', url, asynchronous);
  request.responseType = "arraybuffer";
  request.send(null);
  if(px == undefined){
    return canvas;
  }else{
    return(undefined);
  }
}

function getURL2(bounds) {
  var emptyTileURL = "http://www.maptiler.org/img/none.png";
  var x = bounds.x;
  var y = Math.pow(2, bounds.z) - 1 - bounds.y;
  var z = bounds.z;
  var path = './' + z + '/' + x + '/' + y + '.png';
//  if ((z >= mapMinZoom) && (z <= mapMaxZoom)) {
  if (z >= mapMinZoom) {
    return path;
  } else {
    return emptyTileURL;
  }
}

////////////////////// Sobreescribir algunas funciones de Leaflet
L.TileLayerGoogle = L.TileLayer.extend({
  getTileUrl: function (coords){
    var data = {
      r: L.Browser.retina ? '@2x' : '',
      s: this._getSubdomain(coords),
      x: this.getMainTileX(coords.x, this._getZoomForUrl()),
      y: this.getMainTileY(coords.y, this._getZoomForUrl()),
      z: this._getZoomForUrl()
    };
    if (this._map && !this._map.options.crs.infinite) {
      var invertedY = this._globalTileRange.max.y - coords.y;
      if (this.options.tms) {
        data['y'] = invertedY;
      }
      data['-y'] = invertedY;
    }

    return L.Util.template(this._url, L.extend(data, this.options));
  },
  getMainTileY: function(coord, zoom){
    return coord;
  },
  getMainTileX: function(coord, zoom){
    modulo = Math.pow(2, zoom);
    posicion_x = coord % modulo;
    if(posicion_x<0){
      posicion_x=modulo+posicion_x;
    }
    return posicion_x;
  }
});

L.tileLayerGoogle = function (url, options) {
  return new L.TileLayerGoogle(url, options);
};

L.TileLayerPro = L.TileLayer.extend({
  getTileUrl: function (coords){
    return "doesnt_matter";
  },
  createTile: function(coords, done){
    return getURL(coords, done);
  },
  getMainTileY: function(coord, zoom){
    var ymax = 1 << zoom;
    var y = ymax - coord -1;
    return y;
  },
  getMainTileX: function(coord, zoom){
    var x = coord % Math.pow(2,zoom);
    if(x<0){
      x=Math.pow(2,zoom)+x;
    }
    return x;
  }
});

L.tileLayerPro = function (url, options) {
  return new L.TileLayerPro(url, options);
};

////////////////////////////////////////////////////////

 var map;

 var poly = function(x, varargs) {
  var i = arguments.length - 1, n = arguments[i];
  while (i > 1) {
    n = n * x + arguments[--i];
  }
  return n;
};

var paletteBuffer = new ArrayBuffer(256*3);
var palette = new Uint8Array(paletteBuffer);

var palrgb = ["#FFFFFF", "#FFFFFD", "#FFFFFC", "#FFFFFA", "#FFFFF9", "#FFFFF8", "#FFFFF6", "#FFFFF5", "#FFFFF4", "#FFFFF2", "#FFFFF1", "#FFFFF0", "#FFFFEE", "#FFFFED", "#FFFFEC", "#FFFFEA", "#FFFFE9", "#FFFFE8", "#FFFFE6", "#FFFFE5", "#FFFFE4", "#FFFFE2", "#FFFFE1", "#FFFFE0", "#FFFFDE", "#FFFFDD", "#FFFFDC", "#FFFFDA", "#FFFFD9", "#FEFED8", "#FDFED6", "#FDFED5", "#FCFED3", "#FCFDD2", "#FBFDD1", "#FAFDCF", "#FAFDCE", "#F9FCCC", "#F8FCCB", "#F8FCC9", "#F7FCC8", "#F6FBC7", "#F6FBC5", "#F5FBC4", "#F5FBC2", "#F4FAC1", "#F3FAC0", "#F3FABE", "#F2FABD", "#F1F9BB", "#F1F9BA", "#F0F9B9", "#EFF9B7", "#EFF8B6", "#EEF8B4", "#EEF8B3", "#EDF8B1", "#ECF7B1", "#EBF7B1", "#E9F6B1", "#E8F6B1", "#E7F5B1", "#E5F5B1", "#E4F4B1", "#E3F4B1", "#E1F3B1", "#E0F3B1", "#DFF2B2", "#DDF2B2", "#DCF1B2", "#DBF0B2", "#D9F0B2", "#D8EFB2", "#D7EFB2", "#D5EEB2", "#D4EEB2", "#D3EDB3", "#D1EDB3", "#D0ECB3", "#CFECB3", "#CDEBB3", "#CCEBB3", "#CBEAB3", "#C9EAB3", "#C8E9B3", "#C7E9B4", "#C4E8B4", "#C1E7B4", "#BFE6B4", "#BCE5B4", "#BAE4B5", "#B7E3B5", "#B5E2B5", "#B2E1B5", "#B0E0B6", "#ADDFB6", "#ABDEB6", "#A8DDB6", "#A5DCB7", "#A3DBB7", "#A0DAB7", "#9ED9B7", "#9BD8B8", "#99D7B8", "#96D6B8", "#94D5B8", "#91D4B9", "#8FD3B9", "#8CD2B9", "#8AD1B9", "#87D0BA", "#84CFBA", "#82CEBA", "#7FCDBA", "#7DCCBB", "#7BCBBB", "#79CABB", "#76CABC", "#74C9BC", "#72C8BC", "#70C7BD", "#6EC6BD", "#6CC5BD", "#69C5BE", "#67C4BE", "#65C3BE", "#63C2BF", "#61C1BF", "#5EC1BF", "#5CC0BF", "#5ABFC0", "#58BEC0", "#56BDC0", "#53BDC1", "#51BCC1", "#4FBBC1", "#4DBAC2", "#4BB9C2", "#49B8C2", "#46B8C3", "#44B7C3", "#42B6C3", "#40B5C3", "#3FB4C3", "#3EB2C3", "#3CB1C3", "#3BB0C3", "#3AAFC3", "#38ADC3", "#37ACC2", "#36ABC2", "#35A9C2", "#33A8C2", "#32A7C2", "#31A5C2", "#30A4C2", "#2EA3C1", "#2DA1C1", "#2CA0C1", "#2A9FC1", "#299EC1", "#289CC1", "#279BC1", "#259AC0", "#2498C0", "#2397C0", "#2296C0", "#2094C0", "#1F93C0", "#1E92C0", "#1D91C0", "#1D8FBF", "#1D8DBE", "#1D8BBD", "#1D89BC", "#1D87BB", "#1E86BA", "#1E84BA", "#1E82B9", "#1E80B8", "#1E7FB7", "#1E7DB6", "#1F7BB5", "#1F79B4", "#1F77B4", "#1F75B3", "#1F74B2", "#2072B1", "#2070B0", "#206EAF", "#206CAF", "#206BAE", "#2069AD", "#2167AC", "#2165AB", "#2163AA", "#2162A9", "#2160A9", "#215EA8", "#225DA7", "#225BA6", "#225AA6", "#2258A5", "#2257A4", "#2255A3", "#2254A3", "#2252A2", "#2251A1", "#234FA1", "#234EA0", "#234C9F", "#234B9F", "#23499E", "#23489D", "#23469C", "#23459C", "#23439B", "#23429A", "#24409A", "#243F99", "#243D98", "#243C98", "#243A97", "#243996", "#243795", "#243695", "#243494", "#243393", "#233291", "#22328F", "#21318C", "#20308A", "#1F2F88", "#1E2E86", "#1D2E84", "#1C2D82", "#1B2C80", "#1A2B7E", "#192A7B", "#182979", "#172977", "#162875", "#152773", "#142671", "#13256F", "#12256D", "#11246B", "#102368", "#0F2266", "#0E2164", "#0D2162", "#0C2060", "#0B1F5E", "#0A1E5C", "#091D5A", "#081D58"];

function pal2rgb(x)
{
  if(x < 0)
  {
    x = 0;
  }
  if(x > 255)
  {
    x = 255;
  }

  return palrgb[x];

//  var r = palette[0+3*x];
//  var g = palette[1+3*x];
//  var b = palette[2+3*x];

//  return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

function hexToRgb(hex) {
    // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
    var shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, function(m, r, g, b) {
        return r + r + g + g + b + b;
    });

    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

var clickPopup;
function init(){

  zip.workerScriptsPath = "lib/";

  var i, x, y;

  for(i=0;i<256;i++)
  {
    palette[i*3+0] = hexToRgb(palrgb[i]).r;
    palette[i*3+1] = hexToRgb(palrgb[i]).g;
    palette[i*3+2] = hexToRgb(palrgb[i]).b;
  }

  var options = {
    controls: [],
    // projection: "EPSG:900913",
    // displayProjection: new OpenLayers.Projection("EPSG:4326"),
    minZoom: mapMinZoom, 
    // maxZoom: mapMaxZoom,
    center: center, 
    zoom: zoom,
    // zoomControl: false,
    attributionControl: false
  };
  map = L.map("map", options);

  attribution = L.control.attribution({
    prefix:false
  });
  attribution.addTo(map);

  var customMap = L.layerGroup();

  function newDroughtOverlayMap(mapFunction){
    droughtOverlayMapAux = L.tileLayerPro(mapFunction, {
      zIndex: 6,
      bounds: marginBounds
    });
    return droughtOverlayMapAux;
  }
 
  droughtOverlayMap = newDroughtOverlayMap("getURL");

  var urlLayer = 'http://{s}.tile.openstreetmap.se/hydda/base/{z}/{x}/{y}.png';
  hyddaBase = L.tileLayerGoogle(urlLayer, {
    zIndex: 1,
    ext: 'png'
  });
  
  var urlLayer = 'http://korona.geog.uni-heidelberg.de/tiles/adminb/x={x}&y={y}&z={z}';
  var googleLabelLayer = L.tileLayerGoogle(urlLayer, {
    // attribution: '<a href="info.html">Reference the data</a>' + ' | ' + 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>' + ' | ' + 'Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>' + ' | ' + '<a href="http://leafletjs.com">Leaflet</a>',
    attribution: '<a href="info.html">Reference the data</a>' + ' | ' + '<a href="http://stamen.com">Stamen Design</a>' + ' | ' + '<a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>' + ' | ' + '<a href="http://leafletjs.com">Leaflet</a>',
    subdomains: 'abcd',
    minZoom: 0,
    maxZoom: 20,
    ext: 'png',
    zIndex: 10
  });

  var urlLayer = 'http://stamen-tiles-{s}.a.ssl.fastly.net/toner-labels/{z}/{x}/{y}.{ext}';
  var googleLabelLayer2 = L.tileLayerGoogle(urlLayer, {
    // attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    subdomains: 'abcd',
    minZoom: 0,
    maxZoom: 20,
    ext: 'png',
    zIndex: 14
  });
  
  customMap.addLayer(hyddaBase);
  customMap.addLayer(droughtOverlayMap);
  customMap.addLayer(googleLabelLayer);
  customMap.addLayer(googleLabelLayer2);

  customMap.addTo(map);

  if(times.length>1){
    var slider = L.control.slider(function(value) { 
    }, {
      min: 0,
      max: times.length-1, 
      value: timeI,
      step: 1,
      size: '250px',
      orientation:'horizontal', 
      id: 'slider',
      logo: 'Time',
      increment:  true,
      getValue: function(value){
        timeI = value;        
        if(customMap.hasLayer(droughtOverlayMap) && map.hasLayer(customMap)){
          customMap.removeLayer(droughtOverlayMap)
          customMap.addLayer(droughtOverlayMap);
        }
        updateURL();
        return times[value];
      }
    });
  }

  var mouseTimeOut;
  var popup;
  
  map.on('mousemove', function(event) {
    // Mostrar valor del punto actual seleccionado
    var mousemoveValue = function(coor){
      if(coor > -1.E-37){  
        popup = L.popup({autoPan:false,
          closeButton:false, 
          autoClose:true,
          className:'custom'
        })
        .setLatLng(event.latlng) 
        .setContent("Value " + coor)
        .openOn(map);
      };
    };
    clearTimeout(mouseTimeOut);
    mouseTimeOut = setTimeout(function(){
      coor = extractCoorZoom(event.latlng, zoom, mousemoveValue)
    }, 500);
    if(popup != undefined){
      map.closePopup(popup);
    }          
  });

  map.on('move', function(event) {  
    if(times.length>1){ 
      slider._collapse(); 
    }
  });

  var dblclick = false;
  map.on('dblclick', function(event) {  
    dblclick = true;
    clickPopup.remove();
  });

  function showClickPopup(event) {
    dblclick = false;
    setTimeout(function() {
      if(times.length>1){
        slider._collapse();
      }
      if(!dblclick){
        showPopup(event.latlng, true);
      }
    }, 500);   
  }

  function showPopup(latlng, update=false) { 
      var launchPop = function(value){
        if(value>0){
          clickPopup
          .setLatLng(latlng)
          .addTo(map)
          .value = value
        }
        if(update){
          controlCoordinates._update({latlng: latlng});
        }
      }
      coor = extractCoorZoom(latlng, 9, launchPop, true)    
  }

  var returnClickPopUp = function(nothing, options){
    if(clickPopup){
      clickPopup.remove();
    }
    clickPopup = L.marker([center.lat, center.lng]);
    clickPopup.showClickPopup = showClickPopup;
    clickPopup.showPopup = showPopup;
    return clickPopup;
  }
  clickPopup = returnClickPopUp();
  controlCoordinates = L.control.coordinates({
    position:"bottomleft", //optional default "bottomright" "bottomleft"
    decimals:2, //optional default 4
    decimalSeperator:".", //optional default "."
    labelTemplateLat:'<a onclick="downloadMarkerCSV(event)" href="javascript:void(0);">' + 'Download' + '</a>' + " " + "Lat: {y}", //optional default "Lat: {y}"
    labelTemplateLng:"Lng: {x}", //optional default "Lng: {x}"
    enableUserInput:true, //optional default true
    useDMS:false, //optional default false
    useLatLngOrder: true, //ordering of labels, default false-> lng-lat
    markerType: returnClickPopUp, //optional default L.marker
  }).addTo(map);
  // clickPopup.setLatLng({lat:41.650, lng:-0.883});
  showPopup(center);
  // controlCoordinates._update({latlng: {lat:41.650, lng:-0.883}});

  map.on('click', showClickPopup);
  if(times.length>1){
    slider.addTo(map);
  }
  map.on("zoomend", function (e) { 
    zoom = map.getZoom();
  });
  document.getElementById('map').style.cursor = 'initial';

  function getColor(d) { 
    return pal2rgb(parseInt(255*(d-varMin)/(varMax-varMin)));
  }

  var nGrades = 5;
  var gradesColor = Array.apply(null, Array(nGrades+1)).map(function (_, i) {return parseInt(varMin+i*(varMax-varMin)/nGrades);});

  var legend = L.control({position: 'bottomright', alpha: 1.0});
  legend.onAdd = function (map) { 
    var div = L.DomUtil.create('div', 'info legend'), grades = gradesColor, labels = [];
    div.innerHTML += 'Daily PPT (mm)<br>'; 
    // loop through our density intervals and generate a label with a colored square for each interval 
    for (var i = 0; i < grades.length; i++) { 
      div.innerHTML += '<i style="background:' + getColor(grades[i] + 1) + '"></i> ' + grades[i] + (grades[i + 1] ? '&ndash;' + grades[i + 1] + '<br>' : '+'); 
    } 
    return div; 
  }; 
  legend.addTo(map);
}

