package org.example.enginecheck;
import com.jme3.app.SimpleApplication;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.scene.Geometry;
import com.jme3.scene.shape.Box;
import android.util.Log;
public class Probe extends SimpleApplication {
    @Override public void simpleInitApp() {
        Geometry cube = new Geometry("probe", new Box(1, 1, 1));
        Material material = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
        material.setColor("Color", ColorRGBA.Red);
        cube.setMaterial(material);
        rootNode.attachChild(cube);
        setDisplayFps(false);
        setDisplayStatView(false);
        Log.i("EngineCheck", "jMonkeyEngine 3D initialized");
    }
}
