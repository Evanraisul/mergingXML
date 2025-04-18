#!/usr/bin/env bash

# merge_configs.sh
# Merges two Spring XML ignite configurations (default + custom) into one merged.xml

set -euo pipefail

DEFAULT_CFG="default-config.xml"
CUSTOM_CFG="custom-config.xml"
OUTPUT_CFG="merged.xml"

# Inline Python merge logic
python3 - <<PYTHON
import xml.etree.ElementTree as ET
import sys

# Register default namespace
NS = 'http://www.springframework.org/schema/beans'
ET.register_namespace('', NS)

# Recursive merge of child elements
def merge_elements(target, source):
    for child_src in source:
        tag_src = child_src.tag
        name_src = child_src.get('name')
        print(name_src)
        class_src = child_src.get('class')
        print(class_src)
        match = None
        for child_tgt in target:
            if child_tgt.tag != tag_src:
                continue
            if name_src and child_tgt.get('name') == name_src:
                print(name_src)
                match = child_tgt
                break
            if class_src and child_tgt.get('class') == class_src:
                print(class_src)
                match = child_tgt
                break
            if not name_src and not class_src:
                print(name_src)
                match = child_tgt
                break
        if match is None:
            target.append(child_src)
            print(child_src)
        else:
            if list(child_src):
                merge_elements(match, child_src)
            else:
                idx = list(target).index(match)
                print(child_src)
                print(match)
                target.remove(match)
                target.insert(idx, child_src)

# Merge two IgniteConfiguration beans
def merge_configs(default_file, custom_file, output_file):
    tree_def = ET.parse(default_file)
    tree_cust = ET.parse(custom_file)
    root_def = tree_def.getroot()
    root_cust = tree_cust.getroot()

    xpath = f".//{{{NS}}}bean[@class='org.apache.ignite.configuration.IgniteConfiguration']"
    cfg_def = root_def.find(xpath)
    cfg_cust = root_cust.find(xpath)
    if cfg_def is None or cfg_cust is None:
        print("Error: IgniteConfiguration bean not found.", file=sys.stderr)
        sys.exit(1)

    # Merge properties
    for prop_cust in cfg_cust.findall(f"{{{NS}}}property"):
        print(prop_cust)
        name = prop_cust.get('name')
        print(name)
        prop_def = cfg_def.find(f"{{{NS}}}property[@name='{name}']")
        print(prop_def)
        if prop_def is None:
            cfg_def.append(prop_cust)
        else:
            if list(prop_cust):
                merge_elements(prop_def, prop_cust)
            else:
                idx = list(cfg_def).index(prop_def)
                print(idx)
                cfg_def.remove(prop_def)
                cfg_def.insert(idx, prop_cust)

    # Write output
    tree_def.write(output_file, encoding='UTF-8', xml_declaration=True)

# Execute merge using variables from the parent script
merge_configs("$DEFAULT_CFG", "$CUSTOM_CFG", "$OUTPUT_CFG")
PYTHON

echo "Merged XML written to $OUTPUT_CFG"
