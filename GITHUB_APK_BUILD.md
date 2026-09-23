# GitHub APK Build

1. Create a GitHub repository named `earn-battle`.
2. Upload the contents of this ZIP to the repository root.
3. Push to `main` (or `master`).
4. Open GitHub -> Actions -> `Build Earn Battle APK`.
5. Wait for the workflow to finish.
6. Open the completed workflow run.
7. Under **Artifacts**, download `earn-battle-release-apk`.
8. Extract the downloaded artifact and install `app-release.apk` on Android.

The workflow uses Flutter stable and creates a release APK.

IMPORTANT:
- This builds the APK; it does not deploy the backend.
- The current app's backend URL is configured in `lib/main.dart`.
- For a real phone, the backend must be reachable from the phone (not localhost/10.0.2.2).
- For production, configure a secure HTTPS backend, proper payment integration,
  authentication, admin authorization, and applicable legal/compliance requirements.
