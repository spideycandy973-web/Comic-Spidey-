# Native Android release signing

The first public native APK, `v0.4.0-native`, uses package
`com.comicspidey.nativegame` and signing certificate SHA-256
`6e1314880e4b8a95fc480df7e7dfbdfe308c6499df7dfd36765d9b7018f32699`.
Updates to this package must use **that same key**. Do not use the temporary CI
key, the old WebView key, the public GamersHub key, or generate another key.

The owner's private Google Drive folder named **Comic Spidey Android signing
backup (private)** contains three required files:

- `recovery-transport-private.pem`
- `native-release-signing-envelope.enc`
- `native-release-signing-backup.enc`

All three were downloaded and verified after upload; the recovered signing
certificate was checked against the APK. The folder had only the owner's Drive
permission at publication. Keep it private; do not commit, share, print or
attach these files or the recovered password to a public issue or workflow log.
Losing them means the existing Android installation cannot be updated with a
new build signed by a different key.

For a future authorized release, download the three files into a private,
access-controlled temporary directory and recover the PKCS#12 keystore there.
These commands use password **files** so passwords are not printed:

```sh
umask 077
openssl pkeyutl -decrypt -inkey recovery-transport-private.pem \
  -in native-release-signing-envelope.enc -out envelope-pass.txt \
  -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in native-release-signing-backup.enc -out signing-backup.tar \
  -pass file:envelope-pass.txt
tar -xf signing-backup.tar
```

The recovered files are `release.p12` and `password.txt`; the alias is
`comicspidey`. Verify the recovered certificate fingerprint before signing and
verify the signed APK with Android `apksigner` afterward. Configure Godot's
release keystore through a secure environment, and securely remove the
recovered files after use. Never put credentials into a public GitHub Actions
workflow, artifact, release, log or repository. Avoid public self-hosted runners.
The one-time draft workflow is not an update-signing workflow; it generated the
first release key and must not be used to rotate it.
