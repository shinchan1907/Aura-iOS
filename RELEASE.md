# Installing Aura on Your iPhone

Because you are developing Aura on a Windows machine, the compiled source code cannot simply be drag-and-dropped onto an iPhone. iOS enforces strict code signing policies to ensure app security.

To install Aura on a physical device, you must choose one of the following distribution routes.

---

## Route A: TestFlight (Highly Recommended)
*Requires a paid Apple Developer Program membership ($99/yr).*

TestFlight is Apple's official beta distribution system. Once configured, you can easily install Aura on your iPhone and push updates automatically without needing to plug your phone into a computer.

### Step 1: Configure App Store Connect
1. Log in to [App Store Connect](https://appstoreconnect.apple.com).
2. Register a new Bundle ID matching `project.yml` (e.g., `com.aura.app`). Ensure you enable the **App Groups** and **Push Notifications** capabilities if required.
3. Create a new App record for Aura.

### Step 2: Configure GitHub Secrets
To allow GitHub Actions to compile and sign the app, you need to export your distribution certificate (`.p12`) and Provisioning Profile from your Apple Developer account.
1. Add the following to your GitHub repository **Secrets**:
   - `BUILD_CERTIFICATE_BASE64`: The base64-encoded `.p12` certificate.
   - `P12_PASSWORD`: The password for the `.p12` certificate.
   - `BUILD_PROVISION_PROFILE_BASE64`: The base64-encoded provisioning profile.
   - `KEYCHAIN_PASSWORD`: A random temporary password for the CI runner.
   - `PROVISIONING_PROFILE_NAME`: The exact string name of your provisioning profile.
   - `EXPORT_OPTIONS_PLIST`: A base64-encoded `ExportOptions.plist` configured for App Store deployment.

### Step 3: Trigger the Release Workflow
1. Go to the **Actions** tab on your GitHub repository.
2. Select the **iOS Release (App Store / TestFlight)** workflow.
3. Click **Run workflow**. 
4. The workflow will generate the `Aura.ipa` file. You can configure the workflow to automatically upload to TestFlight via the App Store Connect API.

### Step 4: Install on iPhone
1. Download the **TestFlight** app from the App Store on your iPhone.
2. Accept the tester invitation sent to your Apple ID.
3. Tap **Install** next to Aura.

---

## Route B: Direct Installation (AltStore / Sideloadly)
*Can be done with a free Apple Developer account, but requires refreshing every 7 days.*

If you do not want to pay for an Apple Developer membership, you can sideload the app. Note that Live Activities (ActivityKit) and Push Notifications can sometimes be temperamental when sideloaded with a free account.

### Step 1: Download the Unsigned Artifact
Currently, the basic `ios.yml` CI workflow only checks that the code compiles. You can modify it to output a `.app` payload, or use a tool to build the `.ipa` using a simulated certificate.

### Step 2: Sideload
1. Install **AltStore** or **Sideloadly** on your Windows machine.
2. Connect your iPhone via USB.
3. Use the sideloading tool to sign the compiled `.ipa` using your free Apple ID and install it to your device.
4. On your iPhone, go to **Settings > General > VPN & Device Management** and trust your Apple ID certificate.
5. (iOS 16+) Go to **Settings > Privacy & Security** and enable **Developer Mode**.

---

## Final Readiness Checklist
- [x] Code successfully compiles on macOS runner via XcodeGen.
- [x] Live Activities and Widgets configured in target bundle.
- [ ] You have secured an Apple Developer Membership (for Route A).
- [ ] You have uploaded signing certificates to GitHub Secrets.
