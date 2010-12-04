/*
OpenLinkMap Copyright (C) 2010 Alexander Matheisen
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it under certain conditions.
See olm.openstreetmap.de/info for details.
*/

function createMap()
{
	// update timestamp of last database update
	getTimestamp();
	// update timestamp every minute
	timer = setInterval('getTimestamp()', 60000);
	// position to zoom on if no permalink is given and geolocation isn't supported
	var startLat = 51.40635;
	var startLon = 10.05257;
	var startZoom = 8;
	// code for showing the loading image in popups
	var loading = '<img src=\"../img/loading.gif\" />';
	// projection
	wgs84 = new OpenLayers.Projection("EPSG:4326");
	OpenLayers.Lang.setCode('de');
	map = new OpenLayers.Map('mapFrame',
	{
		controls: [],
		projection: new OpenLayers.Projection("EPSG:900913"),
		displayProjection: wgs84,
		maxExtent: new OpenLayers.Bounds(-20037508.34,-20037508.34, 20037508.34, 20037508.34),
		numZoomLevels: 19,
		maxResolution: 156543,
		units: 'meters'
	});
	map.addControl(new OpenLayers.Control.PanZoomBar());
	map.addControl(new OpenLayers.Control.ScaleLine());
	map.addControl(new OpenLayers.Control.MousePosition());
	map.addControl(new OpenLayers.Control.LayerSwitcher());
	map.addControl(new OpenLayers.Control.Permalink());
	map.addControl(new OpenLayers.Control.Navigation());
	var mapnikMap = new OpenLayers.Layer.OSM.Mapnik("Mapnik",
	{
		transitionEffect: 'resize'
	});
	var osmarenderMap = new OpenLayers.Layer.OSM.Osmarender("Osmarender",
	{
		transitionEffect: 'resize'
	});
	var wikipediaLayer = new OpenLayers.Layer.Vector("Wikipedia",
	{
		projection: wgs84,
		maxResolution: 10.0,
		visibility: true,
		transitionEffect: 'resize',
		strategies:
		[
			new OpenLayers.Strategy.BBOX({ratio: 2.5})
		],
		protocol: new OpenLayers.Protocol.HTTP(
		{
			url: 'http://olm.openstreetmap.de/api/bbox_wikipedia.php',
			format: new OpenLayers.Format.OSMPOI(
			{
				defaultStyle:
				{
					'externalGraphic': '../img/wikipedia.png',
					'graphicWidth': 16,
					'graphicHeight': 16,
					'graphicXOffset': -8,
					'graphicYOffset': -8,
					'graphicOpacity': 1
				}
			})
		})
	});
	var linkLayer = new OpenLayers.Layer.Vector("Links",
	{
		projection: wgs84,
		maxResolution: 10.0,
		visibility: true,
		transitionEffect: 'resize',
		strategies:
		[
			new OpenLayers.Strategy.BBOX({ratio: 2.5})
		],
		protocol: new OpenLayers.Protocol.HTTP(
		{
			url: 'http://olm.openstreetmap.de/api/bbox_links.php',
			format: new OpenLayers.Format.OSMPOI(
			{
				defaultStyle:
				{
					'externalGraphic': '../img/link.png',
					'graphicWidth': 16,
					'graphicHeight': 16,
					'graphicXOffset': -8,
					'graphicYOffset': -8,
					'graphicOpacity': 1
				}
			})
		})
	});
	linkLayer.events.on({
		featureselected: function(e)
		{
			if (!e.feature.contentHTML)
				e.feature.contentHTML = '<img src=\"../img/loading.gif\" />';
			if (!e.feature.popup)
				e.feature.popup = new OpenLayers.Popup.FramedCloud("popup", new OpenLayers.LonLat(e.feature.geometry.x, e.feature.geometry.y), null, editPopupContent(e.feature.contentHTML), null, true, function(){eventHandlerClick.unselect(e.feature)});
			map.addPopup(e.feature.popup);
			if (e.feature.popup.contentHTML.substr(0, 4) == '<img')
			{
				request = OpenLayers.Request.GET({url: 'http://olm.openstreetmap.de/api/details.php?'+e.feature.data['id'], async: false});
				e.feature.contentHTML = request.responseText;
				var position = new OpenLayers.LonLat(e.feature.geometry.x, e.feature.geometry.y).transform(map.getProjectionObject(), wgs84);
				var id = e.feature.data['id'].split('&');
				e.feature.popup.setContentHTML(editPopupContent(request.responseText, position.lat, position.lon, id[1].substr(5), id[0].substr(3)));
				map.removePopup(e.feature.popup);
				map.addPopup(e.feature.popup);
			}
			if (e.feature.popup)
				map.addPopup(e.feature.popup);
		},
		featureunselected: function(e)
		{
			if (e.feature.popup)
				map.removePopup(e.feature.popup);
		}
	});
	wikipediaLayer.events.on({
		featureselected: function(e)
		{
			if (!e.feature.contentHTML)
				e.feature.contentHTML = '<img src=\"../img/loading.gif\" />';
			if (!e.feature.popup)
				e.feature.popup = new OpenLayers.Popup.FramedCloud("popup", new OpenLayers.LonLat(e.feature.geometry.x, e.feature.geometry.y), null, editPopupContent(e.feature.contentHTML), null, true, function(){eventHandlerClick.unselect(e.feature)});
			map.addPopup(e.feature.popup);
			if (e.feature.popup.contentHTML.substr(0, 4) == '<img')
			{
				request = OpenLayers.Request.GET({url: 'http://olm.openstreetmap.de/api/details.php?'+e.feature.data['id'], async: false});
				e.feature.contentHTML = request.responseText;
				var position = new OpenLayers.LonLat(e.feature.geometry.x, e.feature.geometry.y).transform(map.getProjectionObject(), wgs84);
				var id = e.feature.data['id'].split("&");
				e.feature.popup.setContentHTML(editPopupContent(request.responseText, position.lat, position.lon, id[1].substr(5), id[0].substr(3)));
				map.removePopup(e.feature.popup);
				map.addPopup(e.feature.popup);
			}
			if (e.feature.popup)
				map.addPopup(e.feature.popup);
		},
		featureunselected: function(e)
		{
			if (e.feature.popup)
				map.removePopup(e.feature.popup);
		}
	});
	map.addLayers([mapnikMap, osmarenderMap, linkLayer, wikipediaLayer]);
	var eventHandlerHover = new OpenLayers.Control.SelectFeature([linkLayer, wikipediaLayer],
	{
		highlightOnly: true,
		renderIntent: "temporary",
		eventListeners:
		{
			featurehighlighted: linkLayer.events.listeners['featureselected'][0].func,
			featureunhighlighted: linkLayer.events.listeners['featureunselected'][0].func
		}
	});
	var eventHandlerClick = new OpenLayers.Control.SelectFeature([linkLayer, wikipediaLayer],
	{
		multiple: true,
		toggle: true
	});
	map.addControl(eventHandlerHover);
	map.addControl(eventHandlerClick);
	eventHandlerHover.activate();
	eventHandlerClick.activate();
	// if no permalink is given
	if(!map.getCenter())
	{
		// jump to given start position
		var startPosition = new OpenLayers.LonLat(startLon, startLat).transform(wgs84, map.getProjectionObject());
		map.setCenter(startPosition, startZoom);
		// if geolocation is available
		if (navigator.geolocation && typeof navigator.geolocation.getCurrentPosition != 'undefined')
		{
			// call function to jump to geolocated position
			navigator.geolocation.getCurrentPosition(setGeolocatedPosition);
		}
	}
	else
	{
		var permalinkParts = document.location.href.split("&");
		if (permalinkParts.length == 5)
		if (permalinkParts[3].substr(0, 2) == "id" && permalinkParts[4].substr(0, 10) == "objecttype")
		{
			var popupPosition = new OpenLayers.LonLat(permalinkParts[2].substr(4), permalinkParts[1].substr(4));
			createSearchPopup(permalinkParts[3].substr(3), popupPosition, permalinkParts[4].substr(11));
			map.setCenter(map.getCenter());
		}
	}
	// allow pressing enter instead of clicking the searchbutton
	initEnter();
	// set focus on search input
	document.getElementById('searchBox').focus();
	// load markers without moving the map first
	map.setCenter(map.getCenter());
	// register moving of map
	map.events.register('moveend', map, mapMoved);
}

function createSearchPopup(id, position, osmType)
{
	//var content;
	if (osmType == "node")
	{
		var nodeRequest = OpenLayers.Request.GET(
		{
			url: 'http://olm.openstreetmap.de/api/details.php?type=point&id='+id,
			async: false
		});
	}
	else
	{
		var nodeRequest = OpenLayers.Request.GET(
		{
			url: 'http://olm.openstreetmap.de/api/details.php?type=polygon&id='+id,
			async: false
		});
		if (nodeRequest.responseText == "Nothing found.")
		{
			var nodeRequest = OpenLayers.Request.GET(
			{
				url: 'http://olm.openstreetmap.de/api/details.php?type=way&id='+id,
				async: false
			});
		}
	}
	if (nodeRequest.responseText != "Nothing found." && nodeRequest.responseText.length > 0)
	{
		var content = nodeRequest.responseText;
		content = editPopupContent(content, position.lat, position.lon, osmType, id);
		var popupPosition = new OpenLayers.LonLat(position.lon, position.lat).transform(wgs84, map.getProjectionObject());
		var popup = new OpenLayers.Popup.FramedCloud
		(
			"popup",
			popupPosition,
			null,
			content,
			null,
			true
		);
		map.addPopup(popup);
	}
}

function setGeolocatedPosition(position)
{
	// set position of map to geolocated position
	var startPosition = new OpenLayers.LonLat(position.coords.longitude, position.coords.latitude).transform(wgs84, map.getProjectionObject());
	map.setCenter(startPosition, 13);
}

function reportSpam()
{
	var lat = map.getCenter().transform(map.getProjectionObject(), wgs84).lat;
	var lon = map.getCenter().transform(map.getProjectionObject(), wgs84).lon;
	var osbString = "http://openstreetbugs.schokokeks.org/?zoom="+map.getZoom()+"&lat="+lat+"&lon="+lon;
	var bugWindow = window.open(osbString);
	bugWindow.focus();
}

function showPlace(left, bottom, right, top, id, lat, lon, osmType)
{
	// hide searchbar
	document.getElementById('searchBar').className = 'searchBar';
	var bounds = new OpenLayers.Bounds(left, bottom, right, top).transform(wgs84, map.getProjectionObject());
	map.zoomToExtent(bounds, true);
	var position = new OpenLayers.LonLat(lon, lat);
	createSearchPopup(id, position, osmType);
}

function requestSearch()
{
	var placesList;
	document.getElementById('searchBar').innerHTML = "<b>Laden...</b>";
	var searchString = document.getElementById('searchBox').value;
	if (searchString.length == 0)
		document.getElementById('searchBar').innerHTML = "<b>Leere Eingabe.<br />Nichts gefunden.</b>";
	else
	{
		searchString = searchString.replace(/ /g, "+");
		var searchUrl = "http://olm.openstreetmap.de/nominatim?format=xml&polygon=0&addressdetails=0&q="+searchString;
		var searchRequest = OpenLayers.Request.GET(
		{
			url: searchUrl,
			async: false
		});
		document.getElementById('searchBar').innerHTML = searchRequest.responseText;
		placesList = searchRequest.responseXML.getElementsByTagName('place');
		if (placesList.length > 0)
		{
			for (var i = 0; i < placesList.length; i++)
			{
				var place = placesList[i];
				var placeBoundingbox = place.getAttribute('boundingbox');
				var placeKey = place.getAttribute('class');
				var placeValue = place.getAttribute('type');
				var placeOsmType = place.getAttribute('osm_type');
				var placeName = place.getAttribute('display_name');
				var placeId = place.getAttribute('osm_id');
				var placeLat = place.getAttribute('lat');
				var placeLon = place.getAttribute('lon');
				var placeType = placeKey+"="+placeValue;
				// translation of object types into german
				placeType = translateType(placeType);
				var placeBounds = placeBoundingbox.split(",");
				var placeItem = "<b>"+placeType+"</b><a href=\"javascript:showPlace("+placeBounds[2]+","+placeBounds[0]+","+placeBounds[3]+","+placeBounds[1]+","+placeId+","+placeLat+","+placeLon+",\'"+placeOsmType+"\');\">"+placeName+"</a><br /><br />";
				document.getElementById('searchBar').innerHTML += placeItem;
			}
		}
		else
			document.getElementById('resultList').innerHTML = "<b>Nichts gefunden.</b>";
		// show searchbar
		document.getElementById('searchBar').className = 'searchBarOut';
	}
}

function translateType(placeType)
{
	var translatedType = searchTypesDE[placeType];
	if(typeof translatedType=='undefined')
		return "";
	else
		translatedType += "&nbsp;";
	return translatedType;
}

function editPopupContent(content, lat, lon, objectType, id)
{
	if (objectType == "point")
		objectType = "node";
	else
		objectType = "way";
	var bounds = map.getExtent().transform(map.getProjectionObject(), wgs84).toArray();
	var l = bounds[0];
	var b = bounds[1];
	var r = bounds[2];
	var t = bounds[3];
	content += "<br /><small id=\"popupLinks\"><a href=\"http://olm.openstreetmap.de/?zoom="+map.getZoom()+"&lat="+lat+"&lon="+lon+"&id="+id+"&objecttype="+objectType+"\">Permalink</a>&nbsp;&nbsp;<a href=\"http://www.openstreetmap.org/edit?lat="+lat+"&lon="+lon+"&zoom="+map.getZoom()+"&"+objectType+"="+id+"\" target=\"_blank\">Potlatch</a>&nbsp;&nbsp;<a href=\"http://localhost:8111/load_and_zoom?left="+l+"&right="+r+"&top="+t+"&bottom="+b+"&select="+objectType+id+"\" target=\"josm\" onclick=\"return josm(this.href)\">JOSM</a>&nbsp;&nbsp;<a href=\"http://www.openstreetmap.org/browse/"+objectType+"/"+id+"\" target=\"_blank\">Details</a></small>";
	return content;
}

function josm(url)
{
	var josmFrame = document.getElementById('josmFrame');
	if(josmFrame)
	{
		josmFrame.src = url;
		return false;
	}		
	return true;
}

function initEnter(event)
{
	if (!event)
		event = window.event;
	if(navigator.appName == "Microsoft Internet Explorer")
	{
		if(event.keyCode == 13)
		{
			requestSearch();
		}
	}
	else
	{
		document.captureEvents(Event.KEYPRESS);
		document.onkeypress = keyEvent;
	}
}

function keyEvent(key)
{
	// if enter key was pressed
	if (key.which == "13")
	{
		requestSearch();
	}
}

function hideSearchBar()
{
	// hide searchbar
	document.getElementById('searchBar').className = 'searchBar';
}

function getTimestamp()
{
	var request = OpenLayers.Request.GET(
	{
		url: 'http://olm.openstreetmap.de/api/timestamp.php',
		async: false
	});
	var timestamp = request.responseText;
	document.getElementById('info').innerHTML = "Letzte Aktualisierung: "+timestamp;
}


function mapMoved(event)
{
	if (map.getZoom() < 14)
		document.getElementById("status").innerHTML = "Hineinzoomen, um Marker anzuzeigen.";
	else
		document.getElementById("status").innerHTML = "";
}
