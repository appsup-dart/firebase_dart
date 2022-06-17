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

import androidx.annotation.NonNull;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FirebaseDartFlutterPlugin */
public class FirebaseDartFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private FlutterPluginBinding binding;

  static final String ACTION_AUTH_RECEIVED = "be.appsup.firebase_dart_flutter.ACTION_AUTH_RECEIVED";
  static final String ACTION_RECAPTCHA_RECEIVED = "be.appsup.firebase_dart_flutter.ACTION_RECAPTCHA_RECEIVED";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "firebase_dart_flutter");
    channel.setMethodCallHandler(this);
    binding = flutterPluginBinding;


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
              binding.getApplicationContext().registerReceiver(new BroadcastReceiver() {
                  @Override
                  public void onReceive(Context context, Intent intent) {
                      result.success(bundleToMap(intent.getExtras()));
                      binding.getApplicationContext().unregisterReceiver(this);
                  }
              }, new IntentFilter(ACTION_AUTH_RECEIVED));
              break;
          case "getVerifyResult":
              binding.getApplicationContext().registerReceiver(new BroadcastReceiver() {
                  @Override
                  public void onReceive(Context context, Intent intent) {
                      result.success(bundleToMap(intent.getExtras()));
                      binding.getApplicationContext().unregisterReceiver(this);
                  }
              }, new IntentFilter(ACTION_RECAPTCHA_RECEIVED));
              break;
          default:
              result.notImplemented();
      }



  }

  static private Map<String,Object> bundleToMap(Bundle bundle) {
      Map<String,Object> map = new HashMap<>();

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
