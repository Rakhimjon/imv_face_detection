# 🔐 Episodic: OneID SSO Integration (Case Study 001)

## 📅 Context: 2026-03-31
The project required a secure authentication flow using the official Uzbekistan SSO (OneID).

## 🚀 The Solution: OAuth2 + PKCE

To avoid storing app secrets on the client, we implemented the **Proof Key for Code Exchange (PKCE)** flow.

### 1. The Workflow
1.  **Generate PKCE**: Generate `codeChallenge` and `codeVerifier` locally using the `pkce` package.
2.  **Redirect to WebView**: Open a `WebViewWidget` pointing to the OneID login page with the `codeChallenge`.
3.  **Catch Redirect**: Monitor `onUrlChange` for the `redirectUrl`.
4.  **Extract Code**: Once the redirect happens, extract the `code` parameter from the URL.
5.  **Exchange**: Pass the `code` and `codeVerifier` back to the BLoC to exchange for a JWT token (Infrastructure layer handles the actual POST).

### 2. Implementation Gotchas
-   **ATS (App Transport Security)**: iOS blocked non-HTTPS connections or specific domains. We had to ensure `NSAppTransportSecurity` in `Info.plist` allowed our redirect domain.
-   **WebView Cache**: We found that users stayed logged in even after "logging out." 
    -   *Resolution*: Added `await controller.clearCache()` and `await controller.clearLocalStorage()` before every login attempt.

### 3. Key Files
- [sso_webview_page.dart](file:///Users/MAC/StudioProjects/xizmat_safari_mobile/lib/presentation/pages/login/sso_webview_page.dart)
- `pkce` package dependency.

---

## 🔗 References
- [Brain Schema](../schema/brain_schema.md)
- [State Management Wiki](../wiki/state_management.md)
