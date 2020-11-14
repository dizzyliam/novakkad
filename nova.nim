import htmlparser
import strformat
import strutils
import xmltree
import osproc
import os

# Define colors and formatting
const 
  default = "\e[0m"
  green = "\e[92m"
  blue = "\e[96m"
  red = "\e[91m"
  bold = "\e[1m"

# Define a help string
const helpString = fmt"""

{green}{bold}NOVAKKAD.{default}

Usage:
  nova help
  nova scan [output-file]
  nova image <input-file> [output-file]
"""

# Get temporary directory
let temp = getTempDir()

# Get command line arguments and check
let params = commandLineParams()
if len(params) == 0 or params[0] == "help":
  echo helpString
  quit()

var imageSrc = ""
var outputFile = "out.md"

# Scan with SANE
if params[0] == "scan":
  echo fmt"{blue}{bold}   Info:{default} Scanning..."
  discard execProcess("scanimage", args=["--format=png", "--resolution=1200", "--mode", "col", "--output-file", temp / "scan.png"], options={poUsePath})
  echo fmt"{blue}{bold}   Info:{default} Scanning complete!"
  imageSrc = temp / "scan.png"

  # Try to find output file
  if len(params) > 1:
    outputFile = params[1]

# Or load an image
elif params[0] == "image" and len(params) > 1:
  imageSrc = params[1]

  # Try to find output file
  if len(params) > 2:
    outputFile = params[2]

# Make sure we have an image to use
if imageSrc == "":
  echo fmt"{red}{bold}  Error:{default} No image for OCR."

# Create character whitelist
writeFile(temp / "chars", """
tessedit_char_whitelist ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,?'-\\/!:;+"()'
""")

# Perform OCR
echo fmt"{blue}{bold}   Info:{default} Performing OCR..."
discard execProcess("tesseract", args=[imageSrc, "output", "hocr", temp / "chars"], workingDir=temp, options={poUsePath})
echo fmt"{blue}{bold}   Info:{default} OCR complete!"

# Load tesseract output
echo fmt"{blue}{bold}   Info:{default} Processing page layout..."
let html = loadHtml(temp / "output.hocr")

# Container for page info and one for stats about page layout
var 
  page: seq[tuple[loc: tuple[left, right, up, down: int], content: string]]
  lefts: seq[int]
  rights: seq[int]

# Loop over lines
for i in html.findAll("span"):
  if i.attr("class") == "ocr_line":
    var line: seq[string]

    # Loop over words in line
    for x in i.findAll("span"):
      if x.attr("class") == "ocrx_word":

        # Add confident (or common) words to line
        var text = x.innerText.replace(" ", "")
        if text != "":
          let confidence = parseInt(x.attr("title").split(" ")[^1])
          if confidence >= 5 or text.toLower() in ["is", "the", "a", "i", "or", "but"]:
            
            # If confidence is below a threshold, make some assumptions about what it's really meant to be
            if confidence <= 90:
              text = text.replace(",", ".")
              text = text.replace("..", ".")
            
            line.add(text)

    # Only add lines with words
    if len(line) > 0:

      # Get location
      let 
        values = i.attr("title").split(" ")[1..^1]
        left = parseInt(values[0])
        right = parseInt(values[2])
        up = parseInt(values[1])
        down = parseInt(values[3].replace(";", ""))
      
      # Include stats
      lefts.add(left)
      rights.add(right)

      # Add line with location to page
      page.add((loc: (left:left, right:right, up:up, down:down), content: line.join(" ")))

# Compute left and right margins and center bounds
let
  leftMargin = min(lefts)
  rightMargin = max(rights)
  quarterWidth = (rightMargin - leftMargin) div 4
  leftOfCenter = leftMargin + quarterWidth
  rightOfCenter = rightMargin - quarterWidth

# Start compiling to markdown
var output = ""
for line in page:
  
  # All caps means that a line is a heading
  if line.content == toUpper(line.content):

    # Titles are centered, so get center of line and see if it is in the middle
    let center = (line.loc.left + line.loc.right) div 2
    if center > leftOfCenter and center < rightOfCenter:
      output &= "\n\n# " & line.content.toLower.capitalizeAscii()

    # If not a title, it's a subheading
    else:
      output &= "\n\n## " & line.content.toLower.capitalizeAscii()
  
  # If it's not a heading, it's text!
  else:
    output &= "\n" & line.content

# Save to output file
writeFile(outputFile, output.strip(chars={'\n', ' '}))
echo fmt"{green}{bold}Success:{default} Output saved!"