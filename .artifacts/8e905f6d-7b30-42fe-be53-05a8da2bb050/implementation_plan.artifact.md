# Fix Corrupted PDF Error (Google Drive Link Conversion)

The user is getting a "document corrupted" error because the database contains Google Drive "view" links (e.g., `https://drive.google.com/file/d/.../view`). These links point to an HTML viewer page rather than the raw PDF file. The PDF viewer requires a direct link to the binary PDF data.

## Proposed Changes

### [Component] Utilities

#### [NEW] [url_helpers.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/core/utils/url_helpers.dart)
- Create a utility function `getDirectPdfUrl(String url)` that detects Google Drive links and converts them to direct download links.
- Pattern to match: `https://drive.google.com/file/d/FILE_ID/view...` or `https://drive.google.com/open?id=FILE_ID`
- Conversion target: `https://drive.google.com/uc?export=download&id=FILE_ID`

---

### [Component] UI / Presentation

#### [MODIFY] [materials_screen.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/presentation/screens/materials/materials_screen.dart)
- Integrate the `getDirectPdfUrl` helper in `_PdfViewerScreen`.
- Ensure that both the manual "Fetch as Bytes" (on Web) and the `SfPdfViewer.network` (on Mobile) use the converted direct link.

## Verification Plan

### Automated Tests
- I will run `flutter analyze` to ensure no syntax errors.
- I will verify the regex logic handles the specific URL formats provided by the user.

### Manual Verification
- Test with the specific URLs provided by the user:
    - `https://drive.google.com/file/d/1W3po2ELjahhNFS7c12w3tvnx33c4xk_2/view?usp=drivesdk`
- Confirm that the app no longer shows the "corrupted" error and successfully renders the PDF.
