package net.redsolver.skylauncher

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.TextView
import io.flutter.plugin.platform.PlatformView

internal class NativeView(context: Context, id: Int, creationParams: Map<String?, Any?>?) : PlatformView {
    private val hostView: AppWidgetHostView

    override fun getView(): View {
        return hostView
    }

    override fun dispose() {}

    init {
        val appWidgetId =  creationParams!!["appWidgetId"] as Int

        // val mAppWidgetManager : AppWidgetManager =   creationParams!!["mAppWidgetManager"] as AppWidgetManager
        // val mAppWidgetHost : AppWidgetHost = creationParams!!["mAppWidgetHost"] as AppWidgetHost

        val mAppWidgetHost = AppWidgetHost(context,4242)
        val mAppWidgetManager = AppWidgetManager.getInstance(context);

        mAppWidgetHost.startListening()


        // mAppWidgetManager.
        // mAppWidgetHost.


        val appWidgetInfo = mAppWidgetManager!!.getAppWidgetInfo(appWidgetId)
        // val minWidgetHeight = appWidgetInfo.minHeight.toFloat()
        // val lineHeight: Float = getLineHeight()
        // val lineSize = Math.ceil(minWidgetHeight / lineHeight.toDouble()).toInt()

        hostView = mAppWidgetHost!!.createView(context, appWidgetId, appWidgetInfo)
    }
}
