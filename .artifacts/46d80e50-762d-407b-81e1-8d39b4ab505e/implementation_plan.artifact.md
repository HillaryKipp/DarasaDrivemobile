# Improve Error Handling for Network Issues

The user is encountering raw technical error messages like `ClientException with SocketException: Failed host lookup` when they are not connected to the internet. We need to intercept these errors and provide user-friendly messages.

## User Review Required

> [!IMPORTANT]
> The plan involves creating a global error handler that translates technical exceptions into user-friendly strings. This will affect both UI widgets (like `ErrorView`) and snackbars (like `showAdminError`).

## Proposed Changes

### Core
#### [NEW] [error_handler.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/core/errors/error_handler.dart)
Create a utility function `getErrorMessage(Object error)` that:
- Detects `SocketException` or `ClientException` with host lookup failure and returns "No internet connection. Please check your network settings."
- Detects `TimeoutException` and returns "Connection timed out. Please try again."
- Detects `PostgrestException` (Supabase) and returns a friendly database error message.
- Detects `AuthException` (Supabase) and returns a friendly authentication error message.
- Detects `FormatException` and returns "Received invalid data from the server."
- Handles `HttpException` and other standard Dart/Flutter exceptions.
- Falls back to a generic "Something went wrong" message for unknown errors.

### UI Widgets
#### [MODIFY] [error_view.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/presentation/widgets/error_view.dart)
- Update `ErrorView` to accept an `Object? error` instead of just a `String message`.
- Use the new `getErrorMessage` utility to format the error message if an `error` object is provided.

### Presentation Helpers
#### [MODIFY] [admin_helpers.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/presentation/screens/admin/admin_helpers.dart)
- Update `showAdminError` to use `getErrorMessage(error)` instead of `error.toString()`.

### Repositories (Optional but Recommended)
#### [MODIFY] [admin_repository_impl.dart](file:///C:/Users/hillary.kipkorir/Desktop/darasadrive_mobile/lib/data/repositories/admin_repository_impl.dart)
- Improve `_wrap` to handle a wider range of exceptions and potentially wrap them in a custom `AppException` with friendly messages.

## Verification Plan

### Manual Verification
- Run the app on a device/emulator.
- Disable internet connection.
- Navigate to a screen that fetches data (e.g., Units screen).
- Verify that the error message displayed is user-friendly (e.g., "No internet connection...") instead of the raw `SocketException`.
- Re-enable internet and verify that "Retry" works and data loads.
