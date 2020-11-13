# NOVAKKAD

Novakkad is a command line utility that mostly automates the process of turning typewritten documents into markdown.
It can handle scanning using SANE and optical character recognition with Tesseract, before processing the results
so that manual editing is little required. It also parses the text according to formatting conventions that have
existed since the start of the 20th century, allowing it to automatically recognize titles and headings. Lastly,
Novakkad automatically removes crossed out or otherwise mangled words, meaning that typos corrected on the typewriter
are seamlessly digitized.

## Installation

Novakkad can be installed from a clone of this repository using `nimble install`. A listing on the nimble repository
is coming soon.

## Usage

Novakkad can be used with the `nova` command. A reference can be printed to the terminal with `nova help`.

To scan and process a document, use the `scan` mode like so:
```
nova scan
```
The output filename defaults to `out.md`, but can be manually set:
```
nova scan file.md
```

To proccess from an image, use the `image` mode like so:
```
nova image image.png
```
The image mode can also take a custom filename:
```
nova image image.png file.md
```

## How does it work?

Once it has received an image from the user or from SANE, Novakkad runs it through Tesseract with a custom character whitelist to
help prevent errors. Detected words that fall below a very low confidence threshold are ignored, unless they resemble common words.
Words that fall below a much higher, but still not ideal, confidence threshold are heavily doctored in order to minimize punctuation errors.
Finally, lines of text that appear to be centered and are in all caps are treated as a title, and those that are the latter only are
considered headings. Then **\*poof\***, you have a markdown file.

## What's with the name?

*Novakkad* is the name of a planet from Ken Macleod's excellent science fiction series *Engines of Light*. It is a place where old meets new;
an ancient people trade in advanced medicines and computers in front of exotic clay houses, while light-speed ships unload overhead.
This utility is slightly less exciting, but I thought it fitting anyway.