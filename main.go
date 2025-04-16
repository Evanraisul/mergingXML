package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/beevik/etree"
)

// mergeXMLFiles reads two XML files, merges them, and writes the result into outFile.
// xmlFilePath is the path to the configuration XML file.
// dtdFilePath is the path to the DTD/template XML file.
func mergeXMLFiles(xmlFilePath, dtdFilePath, outFile string) error {
	// Read configuration XML content from file.
	xmlBytes, err := ioutil.ReadFile(xmlFilePath)
	if err != nil {
		return fmt.Errorf("failed to read XML file %s: %v", xmlFilePath, err)
	}

	// Read DTD/template XML content from file.
	dtdBytes, err := ioutil.ReadFile(dtdFilePath)
	if err != nil {
		return fmt.Errorf("failed to read DTD file %s: %v", dtdFilePath, err)
	}

	// Parse the configuration XML document.
	configDoc := etree.NewDocument()
	if err := configDoc.ReadFromBytes(xmlBytes); err != nil {
		return fmt.Errorf("failed to parse configuration XML: %v", err)
	}
	configRoot := configDoc.Root()
	if configRoot == nil {
		return fmt.Errorf("configuration XML has no root element")
	}

	// Parse the DTD/template XML document.
	dtdDoc := etree.NewDocument()
	if err := dtdDoc.ReadFromBytes(dtdBytes); err != nil {
		return fmt.Errorf("failed to parse DTD/template XML: %v", err)
	}
	templateRoot := dtdDoc.Root()
	if templateRoot == nil {
		return fmt.Errorf("DTD/template XML has no root element")
	}

	// Clear existing children of the template's root.
	templateRoot.Child = nil

	// Copy each child element from the configuration XML to the template root.
	for _, child := range configRoot.Child {
		// Use Copy() to avoid linking nodes across documents.
		templateRoot.AddChild(child.Parent())
	}

	// Write the merged document to the output file.
	mergedXML, err := dtdDoc.WriteToString()
	if err != nil {
		return fmt.Errorf("failed to convert merged XML to string: %v", err)
	}

	if err := ioutil.WriteFile(outFile, []byte(mergedXML), 0644); err != nil {
		return fmt.Errorf("failed to write merged XML to file %s: %v", outFile, err)
	}

	return nil
}

func main() {
	// File paths - adjust these paths as needed.
	xmlFilePath := "default-config.xml"
	dtdFilePath := "custom-config.xml"
	outFile := "mergedOutput.xml"

	// Merge the two XML files.
	if err := mergeXMLFiles(xmlFilePath, dtdFilePath, outFile); err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	fmt.Printf("Merged XML was successfully written to %s\n", outFile)
}
