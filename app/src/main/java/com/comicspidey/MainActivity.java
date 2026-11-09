package com.comicspidey;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebView;

/** Local-only Canvas prototype hosted in a native landscape Android activity. */
public final class MainActivity extends Activity {
    private WebView game;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN |
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        game = new WebView(this);
        game.setBackgroundColor(0xff0b1027);
        game.getSettings().setJavaScriptEnabled(true);
        game.getSettings().setDomStorageEnabled(true);
        game.loadUrl("file:///android_asset/index.html");
        setContentView(game);
    }

    @Override protected void onPause() {
        if (game != null) {
            game.evaluateJavascript("window.comicGame && window.comicGame.pause()", null);
            game.onPause();
        }
        super.onPause();
    }
    @Override protected void onResume() {
        super.onResume();
        if (game != null) game.onResume();
    }
    @Override public void onBackPressed() {
        if (game != null) game.evaluateJavascript("window.comicGame && window.comicGame.pause()", null);
    }
    @Override protected void onDestroy() {
        if (game != null) { game.destroy(); game = null; }
        super.onDestroy();
    }
}
