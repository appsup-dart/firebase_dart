package be.appsup.firebase_dart_flutter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.Bundle;
import android.os.Build;
import android.content.pm.PackageManager;


import androidx.annotation.NonNull;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;
import java.util.Base64;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.auth.api.phone.SmsRetrieverClient;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;

import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.IntegrityTokenRequest;
import com.google.android.play.core.integrity.IntegrityTokenResponse;

/** FirebaseDartFlutterPlugin */
public class FirebaseDartFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private FlutterPluginBinding binding;

  private Context applicationContext;

  static final String ACTION_AUTH_RECEIVED = "be.appsup.firebase_dart_flutter.ACTION_AUTH_RECEIVED";
  static final String ACTION_RECAPTCHA_RECEIVED = "be.appsup.firebase_dart_flutter.ACTION_RECAPTCHA_RECEIVED";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "firebase_dart_flutter");
    channel.setMethodCallHandler(this);
    binding = flutterPluginBinding;
    applicationContext = binding.getApplicationContext();
  }

  private void bringAppToFront() {
    Intent intent = applicationContext.getPackageManager()
        .getLaunchIntentForPackage(applicationContext.getPackageName());

    if (intent != null) {
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
      applicationContext.startActivity(intent);
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    switch (call.method) {
        case "getSha1Cert":
            try {
                final PackageInfo info = binding.getApplicationContext().getPackageManager()
                        .getPackageInfo(binding.getApplicationContext().getPackageName(), PackageManager.GET_SIGNATURES);

                for (Signature signature : info.signatures) {
                    final MessageDigest md = MessageDigest.getInstance("SHA1");
                    md.update(signature.toByteArray());

                    final byte[] digest = md.digest();
                    final StringBuilder toRet = new StringBuilder();
                    for (int i = 0; i < digest.length; i++) {
                        if (i != 0) toRet.append(":");
                        int b = digest[i] & 0xff;
                        String hex = Integer.toHexString(b);
                        if (hex.length() == 1) toRet.append("0");
                        toRet.append(hex);
                    }

                    result.success(toRet.toString());
                }
            } catch (PackageManager.NameNotFoundException e) {
                result.error("Name not found", e.getMessage(), null);
            } catch (NoSuchAlgorithmException e) {
                result.error("No such algorithm", e.getMessage(), null);
            }
            break;
        case "getAuthResult":
            BroadcastReceiver receiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    result.success(bundleToMap(intent.getExtras()));
                    binding.getApplicationContext().unregisterReceiver(this);
                    bringAppToFront();
                }
            };
            IntentFilter filter = new IntentFilter(ACTION_AUTH_RECEIVED);
            binding.getApplicationContext().registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED);
            break;
        case "getVerifyResult":
            receiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    result.success(bundleToMap(intent.getExtras()));
                    binding.getApplicationContext().unregisterReceiver(this);
                    bringAppToFront();
                }
            };
            filter = new IntentFilter(ACTION_RECAPTCHA_RECEIVED);
            binding.getApplicationContext().registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED);
            break;
        case "isGooglePlayServicesAvailable":
            int v = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(binding.getApplicationContext(), 12451000);
            result.success(v == ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED || v == ConnectionResult.SUCCESS);
            break;
        case "requestIntegrityToken":
            String nonce = call.argument("nonce");
            String projectNumber = call.argument("projectNumber");
            IntegrityManagerFactory.create(binding.getApplicationContext())
                .requestIntegrityToken(
                    IntegrityTokenRequest.builder()
                        .setCloudProjectNumber(Long.parseLong(projectNumber))
                        .setNonce(nonce)
                        .build())
                .addOnSuccessListener(new OnSuccessListener<IntegrityTokenResponse>() {
                    @Override
                    public void onSuccess(IntegrityTokenResponse response) {
                        result.success(response.token());
                    }
                })
                .addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        result.error("Could not get PlayIntegrity token", e.getMessage(), null);
                    }
                });
            break;
        case "getAppSignatureHash": 
            try {
                result.success(getAppSignatureHash());
            } catch (PackageManager.NameNotFoundException e) {
                result.error("Name not found", e.getMessage(), null);
            } catch (NoSuchAlgorithmException e) {
                result.error("No such algorithm", e.getMessage(), null);
            }
            break;  
        case "retrieveSms":
            retrieveSms(result);
            break;
        default:
            result.notImplemented();
      }
  }

private void retrieveSms(@NonNull final Result result) {
    // Get an instance of SmsRetrieverClient, used to start listening for a matching
    // SMS message.
    SmsRetrieverClient client = SmsRetriever.getClient(binding.getApplicationContext());

    // Starts SmsRetriever, which waits for ONE matching SMS message until timeout
    // (5 minutes). The matching SMS message will be sent via a Broadcast Intent with
    // action SmsRetriever#SMS_RETRIEVED_ACTION.
    Task<Void> task = client.startSmsRetriever();

    task.addOnFailureListener(new OnFailureListener() {
        @Override
        public void onFailure(@NonNull Exception e) {
            result.error("Start sms retriever failed", e.getMessage(), null);
        }
    });

    BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Bundle extras = intent.getExtras();
            Status status = (Status) extras.get(SmsRetriever.EXTRA_STATUS);

            switch (status.getStatusCode()) {
                case CommonStatusCodes.SUCCESS:
                    // Get SMS message contents
                    String sms = (String) extras.get(SmsRetriever.EXTRA_SMS_MESSAGE);
                    result.success(sms);
                    break;

                case CommonStatusCodes.TIMEOUT:
                    result.error("Sms retrieve timeout", "", null);
                    break;
            }
            binding.getApplicationContext().unregisterReceiver(this);
        }
    };
    IntentFilter filter = new IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION);
    binding.getApplicationContext().registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED);
  }

  private String getAppSignatureHash() throws PackageManager.NameNotFoundException, NoSuchAlgorithmException {
    String packageName = binding.getApplicationContext().getPackageName();
    final PackageInfo info = binding.getApplicationContext().getPackageManager()
        .getPackageInfo(packageName, PackageManager.GET_SIGNATURES);

    final String appInfo = packageName + " " + info.signatures[0].toCharsString();
    MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
    messageDigest.update(appInfo.getBytes(StandardCharsets.UTF_8));

    byte[] hashSignature = messageDigest.digest();

    // truncated into NUM_HASHED_BYTES
    hashSignature = Arrays.copyOfRange(hashSignature, 0, 9);

    // encode into Base64
    String base64Hash = Base64.getEncoder().withoutPadding().encodeToString(hashSignature);
    base64Hash = base64Hash.substring(0, 11);

    return base64Hash;

  }  

  static private Map<String,Object> bundleToMap(Bundle bundle) {
      Map<String,Object> map = new HashMap<>();

      if (bundle==null) {
        return map;
      }

      for (String k : bundle.keySet()) {
          Object o = bundle.get(k);
          if (o instanceof Bundle) {
              o = bundleToMap((Bundle) o);
          }
          if (o instanceof Uri) {
              o = o.toString();
          }
          map.put(k, o);
      }
      return map;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    binding = null;
  }
}
