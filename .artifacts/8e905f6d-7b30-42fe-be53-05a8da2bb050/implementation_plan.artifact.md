# Fix PDF Loading Blank Screen

The user reports that clicking on a PDF material results in a blank screen. This can be caused by missing platform configurations (Web scripts, Cleartext permissions) or lack of error handling/loading feedback in the PDF viewer screen.

## User Review Required

> [!IMPORTANT]
> This plan includes adding `pdf.js` scripts to `web/index.html` and enabling cleartext traffic for Android and iOS. These are standard requirements for `syncfusion_flutter_pdfviewer` to work reliably across all network conditions and platforms.

## Proposed Changes

### [Component] Platform Configuration

#### [MODIFY] [web/index.html](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/web/index.html)
- Add the necessary `pdf.js` scripts to the `<head>` section to support PDF rendering on Web.

#### [MODIFY] [android/app/src/main/AndroidManifest.xml](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/android/app/src/main/AndroidManifest.xml)
- Add `android:usesCleartextTraffic="true"` to the `<application>` tag to support `http://` URLs.

#### [MODIFY] [ios/Runner/Info.plist](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/ios/Runner/Info.plist)
- Add `NSAppTransportSecurity` with `NSAllowsArbitraryLoads` to support `http://` URLs.

---

### [Component] UI / Presentation

#### [MODIFY] [materials_screen.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/presentation/screens/materials/materials_screen.dart)
- Update `_PdfViewerScreen` to handle loading and error states explicitly.
- Add `onDocumentLoadFailed` callback to `SfPdfViewer.network` to capture and display errors.
- Use `LoadingView` and `ErrorView` (existing widgets) to provide better user feedback.

## Verification Plan

### Automated Tests
- I will run `flutter analyze` to ensure no syntax errors were introduced.

### Manual Verification
- Verify that PDF URLs (both HTTPS and HTTP) load correctly.
- Verify that on Web, the PDF viewer renders correctly (requires `pdf.js` scripts).
- Trigger a load failure (e.g., by using a broken URL) and verify that the `ErrorView` is shown instead of a blank screen.
