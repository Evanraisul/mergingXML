#!/bin/bash

# Check if two files are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 default-config.xml custom-config.xml"
    exit 1
fi

file1="$1"
file2="$2"



# Use Python to merge the XML files
python3 - <<END
import xml.etree.ElementTree as ET

def merge_elements(element1, element2):
    # Iterate over each child in element2
    for child2 in list(element2):
        found = False
        # Check each child in element1
        for child1 in list(element1):
            if child2.tag == child1.tag:
                # Check for 'name' attribute match
                if 'name' in child2.attrib and 'name' in child1.attrib:
                    if child2.attrib['name'] == child1.attrib['name']:
                        element1.remove(child1)
                        element1.append(child2)
                        found = True
                        break
                # Check for 'class' attribute match
                elif 'class' in child2.attrib and 'class' in child1.attrib:
                    if child2.attrib['class'] == child1.attrib['class']:
                        element1.remove(child1)
                        element1.append(child2)
                        found = True
                        break
                # Replace if same tag and no name/class
                else:
                    element1.remove(child1)
                    element1.append(child2)
                    found = True
                    break
        if not found:
            element1.append(child2)

# Parse the input files
tree1 = ET.parse('$file1')
root1 = tree1.getroot()
tree2 = ET.parse('$file2')
root2 = tree2.getroot()

# Namespace mapping
ns = {'beans': 'http://www.springframework.org/schema/beans'}

# Find the IgniteConfiguration beans
config_xpath = ".//beans:bean[@class='org.apache.ignite.configuration.IgniteConfiguration']"
config1 = root1.find(config_xpath, ns)
config2 = root2.find(config_xpath, ns)

if config1 is None or config2 is None:
    print("Error: Could not find IgniteConfiguration bean in one of the files.")
    exit(1)

# Merge properties from config2 into config1
for prop2 in config2.findall('beans:property', ns):
    prop_name = prop2.get('name')
    prop1 = config1.find(f"beans:property[@name='{prop_name}']", ns)
    if prop1 is None:
        # Add the entire property from config2
        config1.append(prop2)
    else:
        # Check if prop2 has no children (leaf node)
        if len(prop2) == 0:
            # Replace the entire property
            config1.remove(prop1)
            config1.append(prop2)
        else:
            # Merge child elements
            merge_elements(prop1, prop2)

# Write the merged XML
tree1.write('merged.xml', encoding='UTF-8', xml_declaration=True)
END

if [ $? -eq 0 ]; then
    echo "Merged XML written to merged.xml"
else
    echo "Error merging XML files"
    exit 1
fi