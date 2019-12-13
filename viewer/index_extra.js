
// function parseDate(input) {
//   if(input!=undefined){
//     input=parseInt(input);
//     return input;
//   }else{
//     return null;
//   }
// }

// function palrgb(varName){
//   //console.log("palrgb " + varName);
//   var palrgbArray;
//   if(varName.includes("climatology")){
//     palrgbArray = ["#FFFFCC", "#FFFECA", "#FFFDC9", "#FFFDC7", "#FFFCC6", "#FFFCC5", "#FFFBC3","#FFFBC2", "#FFFAC0", "#FFF9BF", "#FFF9BE", "#FFF8BC", "#FFF8BB", "#FFF7BA","#FFF7B8", "#FFF6B7", "#FFF5B5", "#FFF5B4", "#FFF4B3", "#FFF4B1", "#FFF3B0","#FFF3AF", "#FFF2AD", "#FFF2AC", "#FFF1AA", "#FFF0A9", "#FFF0A8", "#FFEFA6","#FFEFA5", "#FFEEA3", "#FFEEA2", "#FFEDA1", "#FEEC9F", "#FEEC9E", "#FEEB9D","#FEEB9B", "#FEEA9A", "#FEE999", "#FEE997", "#FEE896", "#FEE795", "#FEE793","#FEE692", "#FEE691", "#FEE590", "#FEE48E", "#FEE48D", "#FEE38C", "#FEE28A","#FEE289", "#FEE188", "#FEE186", "#FEE085", "#FEDF84", "#FEDF82", "#FEDE81","#FEDD80", "#FEDD7E", "#FEDC7D", "#FEDB7C", "#FEDB7A", "#FEDA79", "#FEDA78","#FED976", "#FED875", "#FED774", "#FED673", "#FED571", "#FED370", "#FED26F","#FED16D", "#FED06C", "#FECE6B", "#FECD69", "#FECC68", "#FECB67", "#FECA65","#FEC864", "#FEC763", "#FEC661", "#FEC560", "#FEC35F", "#FEC25D", "#FEC15C","#FEC05B", "#FEBF5A", "#FEBD58", "#FEBC57", "#FEBB56", "#FEBA54", "#FEB853","#FEB752", "#FEB650", "#FEB54F", "#FEB34E", "#FEB24C", "#FDB14B", "#FDB04B","#FDAF4A", "#FDAE4A", "#FDAC49", "#FDAB49", "#FDAA48", "#FDA948", "#FDA847","#FDA747", "#FDA546", "#FDA446", "#FDA345", "#FDA245", "#FDA144", "#FDA044","#FD9E43", "#FD9D43", "#FD9C42", "#FD9B42", "#FD9A41", "#FD9941", "#FD9840","#FD9640", "#FD953F", "#FD943F", "#FD933E", "#FD923E", "#FD913D", "#FD8F3D","#FD8E3C", "#FD8D3C", "#FC8C3B", "#FC8A3B", "#FC883A", "#FC863A", "#FC8439","#FC8238", "#FC8038", "#FC7E37", "#FC7C37", "#FC7A36", "#FC7836", "#FC7635","#FC7434", "#FC7234", "#FC7033", "#FC6E33", "#FC6C32", "#FC6A32", "#FC6831","#FC6630", "#FC6430", "#FC622F", "#FC602F", "#FC5E2E", "#FC5C2E", "#FC5A2D","#FC582D", "#FC562C", "#FC542B", "#FC522B", "#FC502A", "#FC4E2A", "#FB4C29","#FA4B29", "#F94928", "#F94828", "#F84627", "#F74427", "#F64327", "#F64126","#F53F26", "#F43E25", "#F33C25", "#F23B24", "#F23924", "#F13724", "#F03623","#EF3423", "#EE3222", "#EE3122", "#ED2F21", "#EC2D21", "#EB2C20", "#EB2A20","#EA2920", "#E9271F", "#E8251F", "#E7241E", "#E7221E", "#E6201D", "#E51F1D","#E41D1C", "#E31C1C", "#E31A1C", "#E2191C", "#E0181C", "#DF171C", "#DE161D","#DD161D", "#DC151D", "#DA141E", "#D9131E", "#D8121E", "#D7121F", "#D6111F","#D4101F", "#D30F20", "#D20E20", "#D10D20", "#D00D20", "#CF0C21", "#CD0B21","#CC0A21", "#CB0922", "#CA0922", "#C90822", "#C70723", "#C60623", "#C50523","#C40424", "#C30424", "#C10324", "#C00225", "#BF0125", "#BE0025", "#BD0025","#BB0026", "#B90026", "#B70026", "#B50026", "#B30026", "#B10026", "#AF0026","#AD0026", "#AC0026", "#AA0026", "#A80026", "#A60026", "#A40026", "#A20026","#A00026", "#9E0026", "#9C0026", "#9A0026", "#980026", "#960026", "#950026","#930026", "#910026", "#8F0026", "#8D0026", "#8B0026", "#890026", "#870026","#850026", "#830026", "#810026", "#800026"];
//   } else {
//     if(varName.includes("slope")){
//       palrgbArray = ["#67001F", "#69001F", "#6C011F", "#6F0220", "#720320", "#750421", "#780521","#7B0622", "#7E0722", "#810823", "#840923", "#870A24", "#8A0B24", "#8D0C25","#900D25", "#930E26", "#960F26", "#991027", "#9B1027", "#9E1127", "#A11228","#A41328", "#A71429", "#AA1529", "#AD162A", "#B0172A", "#B2192B", "#B41C2D","#B51F2E", "#B6212F", "#B82430", "#B92732", "#BB2A33", "#BC2D34", "#BE2F36","#BF3237", "#C03538", "#C2383A", "#C33B3B", "#C53E3C", "#C6403E", "#C7433F","#C94641", "#CA4942", "#CC4C43", "#CD4F44", "#CE5146", "#D05447", "#D15749","#D35A4A", "#D45D4B", "#D6604D", "#D7624F", "#D86551", "#D96853", "#DA6A55","#DB6D57", "#DD7059", "#DE725B", "#DF755D", "#E0785F", "#E17B61", "#E27D63","#E48065", "#E58368", "#E6856A", "#E7886C", "#E88B6E", "#EA8D70", "#EB9072","#EC9374", "#ED9676", "#EE9878", "#EF9B7A", "#F19E7C", "#F2A07E", "#F3A380","#F4A683", "#F4A886", "#F4AA88", "#F5AC8B", "#F5AE8E", "#F5B090", "#F6B293","#F6B496", "#F7B698", "#F7B99B", "#F7BB9E", "#F8BDA1", "#F8BFA3", "#F8C1A6","#F9C3A9", "#F9C5AB", "#F9C7AE", "#FACAB1", "#FACCB4", "#FACEB6", "#FBD0B9","#FBD2BC", "#FBD4BE", "#FCD6C1", "#FCD8C4", "#FDDBC7", "#FCDCC8", "#FCDDCA","#FCDECC", "#FCDFCE", "#FBE0D0", "#FBE1D2", "#FBE2D4", "#FBE3D6", "#FAE4D7","#FAE5D9", "#FAE7DB", "#FAE8DD", "#F9E9DF", "#F9EAE1", "#F9EBE3", "#F9ECE5","#F9EDE7", "#F8EEE8", "#F8EFEA", "#F8F0EC", "#F8F2EE", "#F7F3F0", "#F7F4F2","#F7F5F4", "#F7F6F6", "#F6F6F6", "#F4F5F6", "#F3F5F6", "#F1F4F6", "#F0F3F5","#EEF3F5", "#EDF2F5", "#EBF1F4", "#EAF1F4", "#E8F0F4", "#E7EFF4", "#E5EEF3","#E4EEF3", "#E2EDF3", "#E1ECF3", "#DFECF2", "#DEEBF2", "#DCEAF2", "#DBE9F1","#D9E9F1", "#D8E8F1", "#D6E7F1", "#D5E7F0", "#D3E6F0", "#D2E5F0", "#D1E5F0","#CEE3EF", "#CCE2EE", "#C9E1ED", "#C7DFED", "#C4DEEC", "#C2DDEB", "#BFDCEB","#BDDAEA", "#BAD9E9", "#B8D8E8", "#B5D7E8", "#B3D5E7", "#B0D4E6", "#AED3E6","#ABD2E5", "#A9D0E4", "#A7CFE4", "#A4CEE3", "#A2CDE2", "#9FCBE1", "#9DCAE1","#9AC9E0", "#98C8DF", "#95C6DF", "#93C5DE", "#90C4DD", "#8DC2DC", "#8AC0DB","#87BEDA", "#84BCD9", "#80BAD8", "#7DB8D7", "#7AB6D6", "#77B4D5", "#74B2D3","#71B0D2", "#6EAED1", "#6BACD0", "#68AACF", "#65A8CE", "#61A6CD", "#5EA4CC","#5BA2CB", "#58A0CA", "#559EC9", "#529CC8", "#4F9AC7", "#4C98C6", "#4996C5","#4694C4", "#4393C3", "#4191C2", "#408FC1", "#3F8DC0", "#3D8BBF", "#3C8ABE","#3B88BD", "#3986BC", "#3884BB", "#3783BA", "#3581B9", "#347FB9", "#337DB8","#317CB7", "#307AB6", "#2F78B5", "#2D76B4", "#2C75B3", "#2B73B2", "#2971B1","#286FB0", "#276DB0", "#256CAF", "#246AAE", "#2368AD", "#2166AC", "#2064AA","#1F62A7", "#1E60A4", "#1D5EA1", "#1C5C9E", "#1A5A9B", "#195898", "#185695","#175493", "#165190", "#154F8D", "#144D8A", "#134B87", "#124984", "#114781","#0F457E", "#0E437B", "#0D4078", "#0C3E75", "#0B3C72", "#0A3A6F", "#09386C","#083669", "#073466", "#063263", "#053061"];
//     } else {
//       if(varName.includes("trend")){
//         palrgbArray = ["#67001F", "#69001F", "#6C011F", "#6F0220", "#720320", "#750421", "#780521", "#7B0622", "#7E0722", "#810823", "#840923", "#870A24", "#8A0B24", "#8D0C25", "#900D25", "#930E26", "#960F26", "#991027", "#9B1027", "#9E1127", "#A11228", "#A41328", "#A71429", "#AA1529", "#AD162A", "#B0172A", "#B2192B", "#B41C2D", "#B51F2E", "#B6212F", "#B82430", "#B92732", "#BB2A33", "#BC2D34", "#BE2F36", "#BF3237", "#C03538", "#C2383A", "#C33B3B", "#C53E3C", "#C6403E", "#C7433F", "#C94641", "#CA4942", "#CC4C43", "#CD4F44", "#CE5146", "#D05447", "#D15749", "#D35A4A", "#D45D4B", "#D6604D", "#D7624F", "#D86551", "#D96853", "#DA6A55", "#DB6D57", "#DD7059", "#DE725B", "#DF755D", "#E0785F", "#E17B61", "#E27D63", "#E48065", "#E58368", "#E6856A", "#E7886C", "#E88B6E", "#EA8D70", "#EB9072", "#EC9374", "#ED9676", "#EE9878", "#EF9B7A", "#F19E7C", "#F2A07E", "#F3A380", "#F4A683", "#F4A886", "#F4AA88", "#F5AC8B", "#F5AE8E", "#F5B090", "#F6B293", "#F6B496", "#F7B698", "#F7B99B", "#F7BB9E", "#F8BDA1", "#F8BFA3", "#F8C1A6", "#F9C3A9", "#F9C5AB", "#F9C7AE", "#FACAB1", "#FACCB4", "#FACEB6", "#FBD0B9", "#FBD2BC", "#FBD4BE", "#FCD6C1", "#FCD8C4", "#FDDBC7", "#FCDCC8", "#FCDDCA", "#FCDECC", "#FCDFCE", "#FBE0D0", "#FBE1D2", "#FBE2D4", "#FBE3D6", "#FAE4D7", "#FAE5D9", "#FAE7DB", "#FAE8DD", "#F9E9DF", "#F9EAE1", "#F9EBE3", "#F9ECE5", "#F9EDE7", "#F8EEE8", "#F8EFEA", "#F8F0EC", "#F8F2EE", "#F7F3F0", "#F7F4F2", "#F7F5F4", "#F7F6F6", "#F6F6F6", "#F4F5F6", "#F3F5F6", "#F1F4F6", "#F0F3F5", "#EEF3F5", "#EDF2F5", "#EBF1F4", "#EAF1F4", "#E8F0F4", "#E7EFF4", "#E5EEF3", "#E4EEF3", "#E2EDF3", "#E1ECF3", "#DFECF2", "#DEEBF2", "#DCEAF2", "#DBE9F1", "#D9E9F1", "#D8E8F1", "#D6E7F1", "#D5E7F0", "#D3E6F0", "#D2E5F0", "#D1E5F0", "#CEE3EF", "#CCE2EE", "#C9E1ED", "#C7DFED", "#C4DEEC", "#C2DDEB", "#BFDCEB", "#BDDAEA", "#BAD9E9", "#B8D8E8", "#B5D7E8", "#B3D5E7", "#B0D4E6", "#AED3E6", "#ABD2E5", "#A9D0E4", "#A7CFE4", "#A4CEE3", "#A2CDE2", "#9FCBE1", "#9DCAE1", "#9AC9E0", "#98C8DF", "#95C6DF", "#93C5DE", "#90C4DD", "#8DC2DC", "#8AC0DB", "#87BEDA", "#84BCD9", "#80BAD8", "#7DB8D7", "#7AB6D6", "#77B4D5", "#74B2D3", "#71B0D2", "#6EAED1", "#6BACD0", "#68AACF", "#65A8CE", "#61A6CD", "#5EA4CC", "#5BA2CB", "#58A0CA", "#559EC9", "#529CC8", "#4F9AC7", "#4C98C6", "#4996C5", "#4694C4", "#4393C3", "#4191C2", "#408FC1", "#3F8DC0", "#3D8BBF", "#3C8ABE", "#3B88BD", "#3986BC", "#3884BB", "#3783BA", "#3581B9", "#347FB9", "#337DB8", "#317CB7", "#307AB6", "#2F78B5", "#2D76B4", "#2C75B3", "#2B73B2", "#2971B1", "#286FB0", "#276DB0", "#256CAF", "#246AAE", "#2368AD", "#2166AC", "#2064AA", "#1F62A7", "#1E60A4", "#1D5EA1", "#1C5C9E", "#1A5A9B", "#195898", "#185695", "#175493", "#165190", "#154F8D", "#144D8A", "#134B87", "#124984", "#114781", "#0F457E", "#0E437B", "#0D4078", "#0C3E75", "#0B3C72", "#0A3A6F", "#09386C", "#083669", "#073466", "#063263", "#053061"];
//       } else { //"varie"
//         palrgbArray = ["#FFFFD9", "#FEFED7", "#FDFED6", "#FDFED5", "#FCFED3", "#FCFDD2", "#FBFDD1", "#FBFDD0", "#FAFDCE", "#F9FDCD", "#F9FCCC", "#F8FCCB", "#F8FCC9", "#F7FCC8", "#F7FBC7", "#F6FBC6", "#F5FBC4", "#F5FBC3", "#F4FBC2", "#F4FAC1", "#F3FABF", "#F3FABE", "#F2FABD", "#F2F9BC", "#F1F9BA", "#F0F9B9", "#F0F9B8", "#EFF9B7", "#EFF8B5", "#EEF8B4", "#EEF8B3", "#EDF8B2", "#ECF7B1", "#EBF7B1", "#EAF7B1", "#E9F6B1", "#E8F6B1", "#E6F5B1", "#E5F5B1", "#E4F4B1", "#E3F4B1", "#E2F3B1", "#E0F3B1", "#DFF2B2", "#DEF2B2", "#DDF1B2", "#DCF1B2", "#DAF0B2", "#D9F0B2", "#D8EFB2", "#D7EFB2", "#D6EFB2", "#D5EEB2", "#D3EEB2", "#D2EDB3", "#D1EDB3", "#D0ECB3", "#CFECB3", "#CDEBB3", "#CCEBB3", "#CBEAB3", "#CAEAB3", "#C9E9B3", "#C7E9B3", "#C6E8B4", "#C4E7B4", "#C1E7B4", "#BFE6B4", "#BDE5B4", "#BBE4B5", "#B8E3B5", "#B6E2B5", "#B4E1B5", "#B2E0B6", "#AFDFB6", "#ADDFB6", "#ABDEB6", "#A9DDB6", "#A6DCB7", "#A4DBB7", "#A2DAB7", "#A0D9B7", "#9DD8B8", "#9BD8B8", "#99D7B8", "#97D6B8", "#94D5B8", "#92D4B9", "#90D3B9", "#8DD2B9", "#8BD1B9", "#89D1B9", "#87D0BA", "#84CFBA", "#82CEBA", "#80CDBA", "#7ECCBB", "#7CCCBB", "#7ACBBB", "#78CABB", "#76C9BC", "#74C9BC", "#72C8BC", "#70C7BD", "#6EC6BD", "#6CC6BD", "#6AC5BD", "#68C4BE", "#66C4BE", "#64C3BE", "#63C2BF", "#61C1BF", "#5FC1BF", "#5DC0BF", "#5BBFC0", "#59BFC0", "#57BEC0", "#55BDC1", "#53BCC1", "#51BCC1", "#4FBBC1", "#4DBAC2", "#4BB9C2", "#49B9C2", "#47B8C3", "#45B7C3", "#43B7C3", "#41B6C3", "#40B5C3", "#3FB4C3", "#3EB3C3", "#3DB1C3", "#3BB0C3", "#3AAFC3", "#39AEC3", "#38ADC3", "#37ACC2", "#36AAC2", "#35A9C2", "#34A8C2", "#32A7C2", "#31A6C2", "#30A5C2", "#2FA4C2", "#2EA2C1", "#2DA1C1", "#2CA0C1", "#2A9FC1", "#299EC1", "#289DC1", "#279BC1", "#269AC1", "#2599C0", "#2498C0", "#2397C0", "#2196C0", "#2094C0", "#1F93C0", "#1E92C0", "#1D91C0", "#1D90BF", "#1D8EBE", "#1D8CBE", "#1D8BBD", "#1D89BC", "#1D87BB", "#1E86BB", "#1E84BA", "#1E83B9", "#1E81B8", "#1E80B8", "#1E7EB7", "#1E7CB6", "#1F7BB5", "#1F79B4", "#1F78B4", "#1F76B3", "#1F74B2", "#1F73B1", "#2071B1", "#2070B0", "#206EAF", "#206CAE", "#206BAE", "#2069AD", "#2168AC", "#2166AB", "#2164AB", "#2163AA", "#2161A9", "#2160A8", "#215EA8", "#225DA7", "#225BA6", "#225AA6", "#2259A5", "#2257A5", "#2256A4", "#2255A3", "#2253A3", "#2252A2", "#2251A1", "#234FA1", "#234EA0", "#234DA0", "#234B9F", "#234A9E", "#23499E", "#23479D", "#23469C", "#23459C", "#23439B", "#23429A", "#24419A", "#244099", "#243E99", "#243D98", "#243C97", "#243A97", "#243996", "#243895", "#243695", "#243594", "#243494", "#243392", "#233290", "#22318E", "#21318C", "#20308A", "#1F2F88", "#1E2F87", "#1D2E85", "#1C2D83", "#1C2C81", "#1B2C7F", "#1A2B7D", "#192A7B", "#182979", "#172978", "#162876", "#152774", "#142772", "#132670", "#12256E", "#12246C", "#11246A", "#102368", "#0F2267", "#0E2265", "#0D2163", "#0C2061", "#0B1F5F", "#0A1F5D", "#091E5B", "#081D59", "#081D58"];
//       }
//     }
//   }
//   //palrgbArray = palrgbArray.reverse(); //Reverse colors
//   return palrgbArray;
// };

// function gradesColor_(gradesColor, varName){
//   if(varName.includes("trend")){
//     gradesColor = [1, 2, 3, 4, 5, 6];
//   }
//   return gradesColor;
// };

// function grades_text_(text, i, varName){
//   if(varName.includes("trend")){
//     switch (i) {
//       case 0:
//         text = "+ p < 0.01";
//         break;
//       case 1:
//         text = "+ p < 0.05";
//         break;
//       case 2:
//         text = "+ p > 0.05";
//         break;      
//       case 3:
//         text = "- p > 0.05";
//         break;
//       case 4:
//         text = "- p < 0.05";
//         break;
//       case 5:
//         text = "- p < 0.01";
//         break;
//       default:
//         text = "¿?";
//         break;
//     }
//     text += '<br>';
//     // text = i + 1 + '<br>';
//   }
//   return text;
// };

// function addLogos(superdiv){
//   // Add logo 2
//   var logo = L.DomUtil.create('img', 'img', superdiv);
//   logo.src = 'images/indecis.jpg';
//   //logo.style.width = '200px';
//   //logo.style.height = '107px';
//   logo.style.width = '300px';
//   // Add logo
//   var logo = L.DomUtil.create('img', 'img', superdiv);
//   logo.src = 'images/IPE_logo_plano_color_sombra.png';
//   logo.style.width = '100px';
//   logo.style.height = '114px';
// }

// topTitle = L.control({position: 'topleft', alpha: 1.0});
// topTitle.onAdd = function (map) {
//   var superdiv = L.DomUtil.create('div', 'supertitle');
//   superdiv.innerHTML += "ETACLI: European Trend Atlas of CLimate Indices";
//   return superdiv;
// }
// function _onMapLoad() {
//   topTitle.addTo(map);
//   map.removeControl(map.zoomControl);
// };
