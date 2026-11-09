package org.example.enginecheck;
import com.jme3.app.AndroidHarness;
public class MainActivity extends AndroidHarness {
    public MainActivity() {
        appClass = "org.example.enginecheck.Probe";
        audioRendererType = null;
    }
}
