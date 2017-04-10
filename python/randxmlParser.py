import xml.etree.ElementTree as ET
import sys
import os.path




file = sys.argv[1]


if os.path.isfile(file):

	tree = ET.parse(file)
		
	root = tree.getroot()

	for x in root.find('./head'):
		print x.text

	

	
