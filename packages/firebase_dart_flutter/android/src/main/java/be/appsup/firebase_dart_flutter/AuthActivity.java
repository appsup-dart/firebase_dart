package be.appsup.firebase_dart_flutter;

import android.app.Activity;
import android.content.Intent;

public class AuthActivity extends Activity {

    @Override
    protected void onResume() {
        super.onResume();

        Intent intent = getIntent();
        switch (intent.getAction()) {
            case Intent
                    .ACTION_VIEW:
                sendBroadcast(new Intent(FirebaseDartFlutterPlugin.ACTION_AUTH_RECEIVED).putExtras(intent));
            finish();
        }
    }
}
