# delphi_ocr_tesseract

Es gibt 3 Funktionen  im DM
  
  - ConvertPDFToTIFF(PDF_DATEI, PFAD_FUER_EXTRACTION)
    Erstellt aus PDF TIFF dateien, bei mehrseitigen PDF werden pro seite ein TIFF erstellt.
    Rückgabe ist eine TArray<string> mit allen TIFF Dateien

  - DateiOCR(TIFF_DATEI)
    Gibt die Texterkennung vom TIFF zurück

  - DateiOCR(TIFF_DATEI, AUSGABE_DATEI)
    Erstellt eine Txt datei mit der Ausgabe von der OCR
