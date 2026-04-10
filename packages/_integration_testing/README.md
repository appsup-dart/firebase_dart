Helpers for integration/smoke testing in this workspace.

## Generate Firebase options

From this package directory, run:

```sh
dart run tool/generate_firebase_web_config.dart
```

The tool calls the Firebase Management API (Application Default Credentials) and writes:

- `lib/_generated/<sanitized_project_id>_options.g.dart` — `FirebaseOptions` for web plus `android` / `ios` maps and a `FirebaseProjectConfig config`
- `lib/_generated/all.dart` — `allConfigs` listing every `*_options.g.dart` in that folder (sorted by filename)

Behavior:

- **No flags:** For each existing `*_options.g.dart`, reads `// projectId: ...` from the file header and regenerates that project’s options from the API, then rebuilds `all.dart` from the folder. If the folder has no options files, it only writes `all.dart` (empty list) and prints a hint to use `--project` first.
- **`--project <id>`:** Regenerates only that project’s file, then rebuilds `all.dart` from the folder.

Options:

- `--project <id>` — Firebase project id (single project only)
- `-h`, `--help` — Show usage
