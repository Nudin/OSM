#!/usr/bin/ruby

# We use REXML
require "rexml/document"

    # Scan XML file
    doc = REXML::Document.new(File.new("way[beer=*]"))
    
    # We inspect each <way>
    doc.elements.each("osm/way") do | way |
	lon = []
	lat = []

	way.elements.each("nd") do | nd |
		id=nd.attributes["ref"]
		doc.elements.each("osm/node") do | node |
		   if node.attributes["id"] == id
			lon[lon.size]=node.attributes["lon"]
			lat[lat.size]=node.attributes["lat"]
		   end
		end
	end
	lonsum = 0
	for l in 0..lon.size
		lonsum = lonsum+lon[l].to_f
	end
	avglon = lonsum / lon.size
	puts("avglon:" + avglon.to_s)
	latsum = 0
	for l in 0..lat.size
		latsum = latsum+lat[l].to_f
	end
	avglat = latsum / lat.size
	puts("avglat:" + avglat.to_s)

	way.elements.each("tag") do | tag |
    	    key=tag.attributes["k"]
    	    value=tag.attributes["v"]
    	    puts("key: "+key+" - value: "+value)
	end
	puts("===\n")
    end
