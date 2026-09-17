package com.cargolink.dz.cargolink

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.view.WindowCompat
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.share.Sharer
import com.facebook.share.model.ShareLinkContent
import com.facebook.share.widget.ShareDialog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.cargolink.dz.cargolink/facebook"
    private lateinit var callbackManager: CallbackManager
    private lateinit var shareDialog: ShareDialog
    private var shareResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        callbackManager = CallbackManager.Factory.create()
        shareDialog = ShareDialog(this)
        shareDialog.registerCallback(
            callbackManager,
            object : FacebookCallback<Sharer.Result> {
                override fun onSuccess(result: Sharer.Result) {
                    shareResult?.success(true)
                    shareResult = null
                }
                override fun onCancel() {
                    shareResult?.success(false)
                    shareResult = null
                }
                override fun onError(error: FacebookException) {
                    shareResult?.success(false)
                    shareResult = null
                }
            }
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareLink" -> {
                    val url = call.argument<String>("url") ?: return@setMethodCallHandler
                    val hashtag = call.argument<String>("hashtag")
                    shareResult = result
                    val shareContent = ShareLinkContent.Builder()
                        .setContentUrl(Uri.parse(url))
                        .apply {
                            if (!hashtag.isNullOrBlank()) {
                                setShareHashtag(
                                    com.facebook.share.model.ShareHashtag.Builder()
                                        .setHashtag(hashtag)
                                        .build()
                                )
                            }
                        }
                        .build()
                    if (ShareDialog.canShow(ShareLinkContent::class.java)) {
                        shareDialog.show(shareContent)
                    } else {
                        shareResult?.success(false)
                        shareResult = null
                    }
                }
                "canShareLink" -> {
                    val canShow = ShareDialog.canShow(ShareLinkContent::class.java)
                    result.success(canShow)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        callbackManager.onActivityResult(requestCode, resultCode, data)
        super.onActivityResult(requestCode, resultCode, data)
    }
}
