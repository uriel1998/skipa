# skipa organizer

skipa means ("organize, arrange, place in order") in Old Norse

![skipa logo](https://raw.githubusercontent.com/uriel1998/skipa/master/skipa.png "logo")

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [How to use](#4-how-to-use)
 5. [TODO](#5-todo)

***

## 1. About

`skipa` is designed to fix and write tags in PDF files so they can be organized 
more easily and more tool-agnostically.  

I personally use four main tools for indexing and searching my PDF paperwork:

* gscan2pdf
* recoll
* TagSpaces

However, I've scanned PDF reciepts without adding keywords or tags or even 
dates before.  `skipa` can be pointed at a single file or at an entire 
directory to read metadata from the PDF itself - and what is in the filename - 
resolve conflicts, and re-write that metadata in the file itself and in 
the filename.

*note: I treat the metadata "Keywords" and the term "tags" interchangably here*

## 2. License

This project is licensed under the MIT license. For the full license, see `LICENSE`.

## 3. Prerequisites

### These may already be installed on your system.

 * `grep`
 * `awk` 
 * `sed` 
 * `pdftohtml`
 * `html2text`
 * `stat`
 * `date`
 * `exiftool`
 * `detox`
 * `xpdf`
 * `yad` https://sourceforge.net/projects/yad-dialog/

## 4. How to use

The filename format that is generated is a combination of what `gscan2pdf` will create
and what `TagSpaces` creates. It is in the format:

`TITLE_With_Spaces_as_underscores-YYYY-MM-DD[TAG TAG TAG].pdf`

Usage is straightforward: 

`skipa.sh [path_to_pdf_files | pdf_file ]`

Any conflict between the metadata will be presented for resolution. Choose the appropriate 
radio button or choose "manual resolution" to edit during the loading process.

Once the metadata is loaded, it will all be presented in one dialog box. Additionally, the 
file will be loaded in `xpdf` to assist if all the metadata is missing. Click **save** to 
rename the file and write the metadata into the file itself.  

While it uses exiftool to read and write metadata to the file, `skipa` is currently 
focusing on PDF files at this time. If asked to work in directory mode, it 
uses the `file` utility to only work on PDF files.

## 5. Todo

#TODO - cli-only?
#TODO - just make sure there's no mismatches mode
#TODO - just make sure there's no empty mode
#TODO - Mendeley renaming and metadata writing
#TODO - is there OCR mode
