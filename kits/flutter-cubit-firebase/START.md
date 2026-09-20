# Starting from this kit

```bash
cp -R kits/flutter-cubit-firebase <your-app>
cd <your-app>
flutterfire configure          # generates lib/firebase_options.dart (.template is reference only)
flutter pub get
```

`CODE_RULES.md` is this kit's contract. The same content lives in `conventions/flutter-cubit-firebase.md`,
so the interview reads it first and **never asks what's already decided.**

Structure: `lib/{models,repositories,cubits,pages,widgets,configs}`.
A repository does CRUD for one collection; all business logic is in cubits.
