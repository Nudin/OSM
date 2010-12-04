#!/usr/bin/ruby

################################
# License
################################

# Name: machKarte.rb (forked of MachMateKate.rb)
# Copyright 2010
# Michael F. Schönitzer <michael ät schoenitzer.de>
# Tanjeff Moos <tanjeff@cccmz.de> (Chaos Computer Club Mainz e.V.)
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


################################
# Globals
################################

# This script downloads data from the OpenStreetMap database and 
# converts it to a format suitable for the OpenLayers API.
#
# Data is downloaded via 'wget', requesting all nodes which are tagged 
# with certain tags. The resulting files are in XML format.  They are parsed 
# (using REXML) and text files are constructed which are fed into an OpenLayers 
# JavaScript program to serve as overlays which makes Augustiner-locations (and 
# others) visible.


# We use REXML
require "rexml/document"

# Parameter -d: no download (use existing XML files). Intended for development 
# puporse.
if (ARGV[0] == "-d")
    $do_download = false
else
    $do_download = true
end

$tag_august="brewery"
$query_august="node[brewery=Augustiner]"
$XML_august="augustiner.xml"
$TXT_august="augustiner.txt"
$count_august = 0;
$date_august = "";

# HTML file generation
$html_infile = "augustkarte.html.in"
$html_outfile = "augustkarte.html"


################################
# Helper functions
################################

# Download data (max. 'try' tries)
#
# Give an URL and under which name the data shall be stored.
# The result is the file 'filename'#
def download(url, filename, try)
    if $do_download
	`wget -nv "#{url}" -t #{try} -O #{filename}`
	if $? != 0
	    puts("Error downloading File.")
	    return 1
	end
    end
return 0
end

# For Downloading the Data, use this function instead.
# It will try several XAPI-Servers
def APIdownload(query, filename)
api_url = [
"http://www.informationfreeway.org/api/0.6/",
"http://xapi.openstreetmap.org/api/0.6/",
"http://osmxapi.hypercube.telascience.org/api/0.6/",
"http://osm.bearstech.com/osmxapi/api/0.6/" ]
   if $do_download
   puts "Starting downloading data from OSM"
puts api_url.length
	for ss in 0...(api_url.length-1)
		puts "\n\t Server: ", api_url[ss]
		$url=api_url[ss]+query;
		r=download($url, filename, 1)
		if r == 0
			return 0
		elsif ss < api_url.length
			puts "Error - trying another server"
		end
	end
   puts "Can't download data from Xapi"
   return 1
   end
end

# Translate englisch cusine/amenity-names into german.
def translate(en)
   en_word = ["restaurant","biergarten","pub","bar","nightclub","cafe","bavarian","german","italian","frensh", "vegetarian","kebab","pizza","burger","sushi","thai","regional","international","greek", "asian","indian","chinese","mexican","brasilian","austrian", "fast_food", "vietnamese", "swabian"]
   de_word = ["Restaurant","Biergarten","Kneipe","Bar","Diskothek","Café","bayrischer","deutscher","italienischer", "französischer","vegetarischer", "Döner/Kebab","Pizza","Burger","Sushi","thailändischer", "regionaler","internationaler","griechischer","asiatischer","indischer","chinesischer", "mexikanischer","brasilianischer","österreichisch", "Fastfood/Imbiss", "vietmanesicher", "schwäbischer"]

   en_array = en.split(/;/)	# We split the text, according to the API at every ';'
   de = ""
   for ss in 0...en_array.length	# Now, check every given word
	if en_array.length > 1
	        de += " und " if ss+1 == en_array.length
	        de += ", " if (1...en_array.length-1) === ss
	end
	word = ""
	for ww in 0...en_word.length	# Serch for translations
	   if en_array[ss].strip == en_word[ww]
		word += de_word[ww]
	   end
   	end
	if word == ""
	   word += en_array[ss].strip #if we can't find an translation, use the original
	   puts "Warnung: Keine Übersetzung gefunden: " + en_array[ss].strip # and warn about
	end
	de += word
   end
   return de
end

## Bring links into the formate 'http://www.***'
def fixlink(link)
 if link =~ /^http.+/
	return link
 elsif link =~ /^www.+/
	return "http://" + link
 else
	return "http://www." + link
 end
end
## Bring links into a nice to view-format without 'http' and ending '/'
def nicelink(link)
  nice=link.sub(/https?:\/\//, "")
  nice=nice.sub(/\/$/, "")
  return nice
end


# Parse an XML file and generate an TXT file suitable for the OpenLayers 
# javascript program.
#
# Params:
#     infile: the filename of the XML file. This file must not include nodes
#             which are not relevant! For each <node> in the file an entry is 
#             added to the outfile!
#     outfile: the filename of the TXT output file
#     search_tag: which tag we search for. If this tag is found in a node, we
#                determine which icon to use.
#     description_extra: is added to the description field (can be "")
#     icons: an hash containing icon filenames as values. The value of the
#            search_tag is used as key into the hash. If the key is not found, 
#            the key "default" is used, therefore always provide an icon for 
#            "default"! The value must be 
#            "path_to_icon.png\tWIDTHxHEIGHT\tOFFSETXxOFFSETY".
#
# Return Values: number of entries written to outfile and the date of the data 
# as found in the parsed infile (attribute xapi:planetDate of <osm> element).
def parse(infile, outfile, search_tag, description_extra, icons)
    # We count the found nodes
    count = 0;

    # Scan XML file
    doc = REXML::Document.new(File.new(infile))
    
    # Open output file and put header
    file = File.new(outfile, File::WRONLY|File::CREAT|File::TRUNC)
    file << "lat\tlon\ttitle\tdescription\ticon\ticonSize\ticonOffset\n"

    # We inspect each <node>
    doc.elements.each("osm/node") do | node |
	# Collect needed data from the tags
	id,lon,lat = nil
	name,street,housenumber,postcode,city,web,phone,mail,fax = nil
	open,amenity,cuisine,wheelchair,wheelchairnote,note = nil
	icon = ""

	# Get Position and id of Objekt for Perma-,Edit- & Details-Link
	id=node.attributes["id"]
	lon=node.attributes["lon"]
	lat=node.attributes["lat"]

    	node.elements.each("tag") do | tag |
    	    key=tag.attributes["k"]
    	    value=tag.attributes["v"]

    	    case key
    	    when search_tag
		# This is the relevant tag; we determine which icon to use
		if icons.has_key?(value)
		    icon=icons[value]
		else
		    icon=icons["default"]
		end
    	    when "name"
    	        name=value
    	    when "addr:street"
    	        street=value
    	    when "addr:housenumber"
    	        housenumber=value
    	    when "addr:postcode"
    	        postcode=value
    	    when "addr:city"
    	        city=value
    	    when "website" #Note: there are two tags for Website-Links
    	        web=value
    	    when "contact:website"
    	        web=value
    	    when "phone" #Note: there are two tags for phonenumbers
    	        phone=value
    	    when "contact:phone"
    	        phone=value
    	    when "contact:email"
    	        mail=value
    	    when "fax"
    	        fax=value
    	    when "amenity"
    	        amenity=translate(value)
    	    when "cuisine"
    	        cuisine=translate(value)
    	    when "opening_hours"
    	        open=value
    	    when "wheelchair"
    	        wheelchair=value
    	    when "note"
    	        note=value
    	    when "wheelchair:description:en"
    	        wheelchairnote=value
    	    when "wheelchair:description:de"
    	        wheelchairnote=value
    	    end
    	end

    	# Print position
    	file << node.attributes["lat"] + "\t"
    	file << node.attributes["lon"] + "\t"

    	# Print title (use name tag if it was found)
    	if name != nil
    	    file << name + "\t"
    	else
    	    file << "Mate-Zugangspunkt\t"
    	end

	# Put address into description field
    	description = ""
    	description += amenity
    	description += " mit " + cuisine + " Küche." if cuisine
    	description += "<br><br>" if street or housenumber or postcode or city

    	description += street + " " if street
    	description += "Hausnumer: "  if housenumber if !street
    	description += housenumber if housenumber
    	description += "<br/>" if street or housenumber
    	description += postcode + " " if postcode
    	description += city if city

	description += "<br/><br/>" if phone or fax or web or mail
    	description += "Tel: " + phone + "<br/>" if phone
    	description += "Fax: " + fax + "<br/>" if fax
    	description += "<a href=\"" + fixlink(web) + "\">" + nicelink(web) + "</a><br/>" if web
    	description += "<a href=\"mailto:" + mail + "\">" + mail + "</a><br/>" if mail

    	description += "<br/>Öffnungszeiten: " + open if open

        description += "<br/><br/>Rollstuhlgerecht!" if wheelchair=="yes"
        description += "<br/><br/>Eingeschränkt Rollstuhlgerecht!" if wheelchair=="limited"
        description += "<br/><br/><b>Nicht</b> Rollstuhlgerecht!" if wheelchair=="no"
        description += "<br/>" + wheelchairnote if wheelchairnote

        description += "<br/><br/>Notiz:" + note if note

	description = "(Keine Informationen verfügbar)" if description == ""
	# Add description_extra to description field
    	if description_extra != ""
	    description += "<br/>" + description_extra
	end

	# Add Edit & Node-links
	description += "<br/><br/><hr/>"
	# The font-size defind here will not be shown (it semms to be overwritten somewere), but you have to set it, otherwise he will fall back to a big font (caused to the <hr>)
	description += "<span style=\"font-size:.6em\"><a href=\"http://www.openstreetmap.org/?lat=" + lat + "&lon=" + lon + "&zoom=18\">OSM-Permalink</a> "
	description += "<a href=\"http://www.openstreetmap.org/edit?lat=" + lat + "&lon=" + lon + "&node=" + id + "&zoom=18\">Edit</a> "
	description += "<a href=\"http://www.openstreetmap.org/browse/node/" + id + "\">Details</a>"
	description += "</span>"

	# Write description field to outfile
    	file << description + "\t"

	# write icon information to outfile
    	file << icon

	# Count the entry
	count += 1
	
	# Put newline for  next entry
	file << "\n"
    end

    # Tidy up
    file.close()

    # Read date
    date = doc.root.attributes["xapi:planetDate"]
    date = date.slice(6,2) + "." + date.slice(4,2) + "." + date.slice(0,4)

    # Return number of found nodes.
    return count, date
end


###########################
# tag: brewery=Augustiner
###########################

# Download data from OSM
r=APIdownload($query_august, $XML_august)
exit -1 if r != 0

icons = Hash.new()
icons["default"] = "./icon_augustiner_30x30.png\t24,24\t-12,-12"
$count_august, $date_august = 
    parse($XML_august, $TXT_august, $tag_august, "", icons)


###########################
# Generate HTML code
###########################
#
# We read a html file and substitute the following patterns:
#
# ##count_august## => number of August nodes

# Open files
infile = File.new($html_infile)
outfile = File.new($html_outfile, File::WRONLY|File::CREAT|File::TRUNC)

# Read one line after another, perform pattern substitution for the current 
# line and write the line to outfile
infile.each_line do |line|
    line.gsub!(/##(.*?)##/) do | match |
	result = $&

	case $1
	when "count_august"
	    result = $count_august
	when "date_august"
	    result = $date_august
	end

	result.to_s
    end
    outfile << line
end

# close files
infile.close()
outfile.close()

#Download the newest OpenBrewpubsMap-File
r=download("http://brewpubs.openstreetmap.de/gen_kml.wsgi?lang=de", "mikro.kml", 1)
	if r != 0
		exit -1
	end

puts("\nAnzahl Der gefundenen Augustiner-Quellen:")
puts($count_august)
puts("Generieren der Karte (wohl) erfolgreich beendet")

#### Be Aware! ####
# The Skript exists normaly with an exitvalue >=0!
# The exitvalue is the number of objects found.
# When errors hapen, it exists with -1.
exit $count_august

