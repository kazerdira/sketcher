package com.example.flutter_project

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
	private val channelName = "sketcher/image_export"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			if (call.method == "saveImage") {
				val path = call.argument<String>("path")
				if (path.isNullOrEmpty()) {
					result.success(false)
					return@setMethodCallHandler
				}
				try {
					val file = File(path)
					if (!file.exists()) {
						result.success(false)
						return@setMethodCallHandler
					}
					val success = savePngToGallery(file)
					result.success(success)
				} catch (e: Exception) {
					result.success(false)
				}
			} else {
				result.notImplemented()
			}
		}
	}

	private fun savePngToGallery(file: File): Boolean {
		return try {
			val resolver = applicationContext.contentResolver
			val fileName = "sketch_${System.currentTimeMillis()}.png"
			val mimeType = "image/png"
			val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
			} else {
				MediaStore.Images.Media.EXTERNAL_CONTENT_URI
			}
			val values = ContentValues().apply {
				put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
				put(MediaStore.Images.Media.MIME_TYPE, mimeType)
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
					put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Sketches")
					put(MediaStore.Images.Media.IS_PENDING, 1)
				}
			}
			val uri = resolver.insert(collection, values) ?: return false
			resolver.openOutputStream(uri)?.use { out ->
				FileInputStream(file).use { input ->
					input.copyTo(out)
				}
			} ?: return false
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				values.clear()
				values.put(MediaStore.Images.Media.IS_PENDING, 0)
				resolver.update(uri, values, null, null)
			}
			true
		} catch (e: Exception) {
			false
		}
	}
}
