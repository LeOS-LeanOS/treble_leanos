package foundation.e.elib.sample
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Button
import androidx.appcompat.app.ActionBarDrawerToggle
import androidx.drawerlayout.widget.DrawerLayout
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar

class MainActivity : AppCompatActivity() {
    private lateinit var actionBarDrawerToggle: ActionBarDrawerToggle
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val dialogButton = findViewById<Button>(R.id.dialog_button)
        dialogButton.setOnClickListener { MaterialAlertDialogBuilder(this)
            .setTitle("Sample Dialog")
            .setMessage("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, ")
            .setPositiveButton("Button") { dialog, _ -> dialog.dismiss() }
            .setNegativeButton("Button") { dialog, _ -> dialog.dismiss() }
            .show() }

        val snackbarButton1 = findViewById<Button>(R.id.snackbar1)
        val snackbarButton2 = findViewById<Button>(R.id.snackbar2)
        val view = findViewById<View>(R.id.view)
        snackbarButton1.setOnClickListener { Snackbar.make(view, "Two line text string. One to two lines is preferable on mobile and tablet.", Snackbar.LENGTH_LONG).show() }
        snackbarButton2.setOnClickListener { Snackbar.make(view, "Two lines with one action. One to two lines is preferable on mobile.", Snackbar.LENGTH_LONG).setAction("button"){}.show() }

        val toolbar = findViewById<MaterialToolbar>(R.id.toolbar)
        val drawer = findViewById<DrawerLayout>(R.id.drawer_layout)
        actionBarDrawerToggle = ActionBarDrawerToggle(this , drawer, R.string.nav_open, R.string.nav_close)
        actionBarDrawerToggle.syncState()
        setSupportActionBar(toolbar)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if(actionBarDrawerToggle.onOptionsItemSelected(item)) {
            return true
        }
        return super.onOptionsItemSelected(item)
    }
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.toolbar_menu, menu)
        return true
    }
}