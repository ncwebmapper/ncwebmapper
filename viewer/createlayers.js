var createLabelLayer = function(minZoom, maxZoom, zIndex){
  return L.tileLayerGoogle('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
      subdomains: 'abcd',
      id: 'fergusrg/clo49bmwh00nv01pfcqr2bb49',        
      accessToken: 'pk.eyJ1IjoiZmVyZ3VzaXBlIiwiYSI6ImNseGx4cXpkbzAyeTYycHNkbmZqaXRxMnEifQ.-3FedaTMcLYlOj-tT_Zi0w',
      minZoom: minZoom,
      maxZoom: maxZoom,
      ext: 'png',
      zIndex: zIndex,
      crossOrigin: "Anonymous"
  });
};
