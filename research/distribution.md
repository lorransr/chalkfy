# Distribution: how a free macOS app reaches users

Answers [#4](https://github.com/lorransr/chalkfy/issues/4). Checked 2026-10-27 against Homebrew 7.0.9.

## Answer

- Signing and notarization cost **$99/year** (Apple Developer Program). There is no free path to a Developer ID. The fee waiver covers nonprofits, accredited schools and government bodies. Individuals do not qualify.
- **Official `homebrew/cask` is closed to chalkfy for now.** It requires notability (a self-submission needs 90 forks, 90 watchers or 225 stars, and the repo must be 30+ days old) and Gatekeeper-passing artefacts, which means signed and notarized.
- **Own tap (`lorransr/homebrew-tap`) works from day one** with no notability bar. Since Homebrew 6.0 users must trust it explicitly. Homebrew deprecated `--no-quarantine`, so even a tap cask cannot help users skip Gatekeeper.
- **Unsigned is usable but costly.** Since macOS Sequoia, users must open System Settings > Privacy & Security > Open Anyway on first launch, because Control-click no longer works. Worse for chalkfy: an ad hoc signed app's identity is tied to the exact build. If chalkfy needs Accessibility or Screen Recording, **users must grant the permission again after every update**.
- **CI is free.** GitHub-hosted runners (macOS included) cost nothing for public repos. Signing in Actions means storing the `.p12` as a base64 secret and importing it into a temporary keychain on the runner.
- **The name `chalkfy` is free.** `brew search chalkfy` finds nothing, there is no `Casks/c/chalkfy.rb` or `Formula/c/chalkfy.rb`, and GitHub has no other `chalkfy` repo. `chalk` is taken (a calculator cask and a formula), so keep the `fy`.

Suggested path: unsigned GitHub Releases plus our own tap now → pay the $99 once there are users → apply to `homebrew/cask` after reaching 225 stars.

## Facts worth keeping

| Fact | Source |
|---|---|
| Notability: 30 forks / 30 watchers / 75 stars, tripled for self-submission; repo < 30 days old normally ineligible | [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy#notability) |
| Software that misses the bar "can generally be maintained in a third-party tap" | same, "Scope and third-party taps" |
| Cask artefacts "must pass Homebrew's Gatekeeper checks and must not require ... Gatekeeper to be disabled or bypassed" | [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks#platform-compatibility-and-macos-security-protections) |
| Exception routes: established maintainer, or "substantial, independently verifiable public interest and multiple requests" | same, "Notability exceptions" |
| Casks failing Gatekeeper are disabled from Sept 2026; `--no-quarantine` deprecated | [Homebrew 5.0.0](https://brew.sh/2025/11/12/homebrew-5.0.0/), [6.0.0](https://brew.sh/2026/06/11/homebrew-6.0.0/) |
| Non-official taps need `brew trust`; `brew install --cask lorransr/tap/chalkfy` trusts only that item | [Tap Trust](https://docs.brew.sh/Tap-Trust) |
| Tap repo should be named `homebrew-*`; `brew tap-new` scaffolds it | [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap) |
| $99/year individual membership | [Apple Developer Program](https://developer.apple.com/programs/) |
| Fee waiver is for legal entities: nonprofit, accredited education, government | [Fee waivers](https://developer.apple.com/help/account/membership/fee-waivers/) |
| Developer ID software built after 2019-06-01 must be notarized; it requires hardened runtime and valid signatures on every executable; the Account Holder signs | [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) |
| Sequoia removed the Control-click Gatekeeper override | [Apple news, Aug 2024](https://developer.apple.com/news/?id=saqachfa) |
| Unsigned or ad hoc code has no stable designated requirement, so privacy (TCC) grants are lost across versions | [TN3127](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements) |
| Actions is free for public repos on standard hosted runners | [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) |
| Importing a `.p12` into a runner keychain from secrets | [Sign Xcode applications](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) |
