package net.redsolver.skylauncher

import android.app.Activity
import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Intent
import android.database.Cursor
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {
    private val CHANNEL = "net.redsolver.skylauncher/native"

    private val REQUEST_BIND_APPWIDGET = 991123
    private val REQUEST_APPWIDGET_PICKED = 991124
    private val REQUEST_APPWIDGET_CONFIGURED = 991125

    private var mAppWidgetManager: AppWidgetManager? = null
    private var mAppWidgetHost: AppWidgetHost? = null


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
      super.configureFlutterEngine(flutterEngine)

        flutterEngine
                .platformViewsController
                .registry
                .registerViewFactory("<homescreen-widget>", NativeViewFactory(

                ))

        mAppWidgetManager = AppWidgetManager.getInstance(context);
        mAppWidgetHost = AppWidgetHost(context,4242)

        mAppWidgetHost!!.startListening()
        // mAppWidgetManager!!.notifyAppWidgetViewDataChanged()

        // mAppWidgetManager.updateAppWidget(p0, p1)(p0, p1)

      MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        // Note: this method is invoked on the main thread.
        call, result ->
          if (call.method == "launchApplicationDetailsSettings") {
              startActivity(
                      Intent(
                              Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                              Uri.parse("package:" + call.arguments)
                      )
              );

              result.success(true)
          } else if (call.method == "appWidget") {

              val appWidgetId = mAppWidgetHost!!.allocateAppWidgetId()


              print("appWidgetId $appWidgetId")

              val pickIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_PICK)
              pickIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
              startActivityForResult(pickIntent, REQUEST_APPWIDGET_PICKED)

              result.success(appWidgetId)
          } else if (call.method == "appWidgetIds") {
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                  result.success(mAppWidgetHost!!.appWidgetIds)
              }else{
                  // TODO Optimize
                  result.notImplemented()
              }
          } else if (call.method == "deleteAppWidgetId") {
              mAppWidgetHost!!.deleteAppWidgetId(call.arguments as Int)

              result.success(true)

          } else if (call.method == "checkTaskerPermission") {
              result.success(TaskerIntent.testStatus(this).toString())
          } else if (call.method == "listTaskerTasks") {
              val c: Cursor? = contentResolver.query(Uri.parse("content://net.dinglisch.android.tasker/tasks"), null, null, null, null)

              // Log.d("MYTAG", "Something something ${c.toString()}")

              var list = arrayListOf<String>();

              if (c != null) {
                  val nameCol: Int = c.getColumnIndex("name")
                  val projNameCol: Int = c.getColumnIndex("project_name")
                  while (c.moveToNext()) list.add( c.getString(projNameCol).toString() + "|||" + c.getString(nameCol))
                  c.close()
              }
              result.success(list)

          } else if (call.method == "invokeTaskerTask") {
              val i = TaskerIntent(call.arguments as String?)
              sendBroadcast(i)
              result.success(true)
          } else {
          result.notImplemented()
        }
      }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if(requestCode == REQUEST_BIND_APPWIDGET){

        }else  if(requestCode == REQUEST_APPWIDGET_PICKED){
            if(resultCode == Activity.RESULT_CANCELED){
                val appWidgetId = data!!.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1);
                if (appWidgetId != -1) {
                    mAppWidgetHost!!.deleteAppWidgetId(appWidgetId);
                }
            }else{
                configureAppWidget(data!!);
            }

        }
        /* else if (resultCode == Activity.RESULT_CANCELED && data != null && (requestCode == REQUEST_APPWIDGET_CONFIGURED || requestCode == REQUEST_APPWIDGET_PICKED)) {
            // if widget was not selected, delete id
            int appWidgetId = data.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1);
            if (appWidgetId != -1) {
                mAppWidgetHost.deleteAppWidgetId(appWidgetId);
            }
        }*/
    }
    private fun configureAppWidget(data: Intent) {
        val appWidgetId = data.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        val appWidgetInfo: AppWidgetProviderInfo = mAppWidgetManager!!.getAppWidgetInfo(appWidgetId)

        addAppWidget(data)
        if (appWidgetInfo.configure != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mAppWidgetHost!!.startAppWidgetConfigureActivityForResult(activity, appWidgetId, 0, REQUEST_APPWIDGET_CONFIGURED, null)
            } else {
                val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
                intent.component = appWidgetInfo.configure
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                try {
                    startActivityForResult(intent, REQUEST_APPWIDGET_CONFIGURED)
                } catch (e: SecurityException) {
                    
                }
            }
        }
    }

    private fun addAppWidget(data: Intent) {
        val appWidgetId = data.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        val appWidgetInfo = mAppWidgetManager!!.getAppWidgetInfo(appWidgetId)
        val minWidgetHeight = appWidgetInfo.minHeight.toFloat()
        // val lineHeight: Float = getLineHeight()
        // val lineSize = Math.ceil(minWidgetHeight / lineHeight.toDouble()).toInt()

        val hostView: AppWidgetHostView = mAppWidgetHost!!.createView(this, appWidgetId, appWidgetInfo)

/*         print("widgetId $appWidgetId");
        print("widgetId appWidgetInfo.minHeight  ${appWidgetInfo.minHeight}");
        print("widgetId $appWidgetId"); */


    }

    override fun onFlutterSurfaceViewCreated(flutterSurfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(flutterSurfaceView)
        flutterSurfaceView.setZOrderMediaOverlay(true)
        flutterSurfaceView.holder.setFormat(PixelFormat.TRANSPARENT)
    }
}
