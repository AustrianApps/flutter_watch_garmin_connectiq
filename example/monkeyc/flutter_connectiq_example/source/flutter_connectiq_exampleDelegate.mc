import Toybox.Lang;
import Toybox.WatchUi;

class flutter_connectiq_exampleDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        System.println("onMenu");
        WatchUi.pushView(new Rez.Menus.MainMenu(), new flutter_connectiq_exampleMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onKey(keyEvent) as Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_DOWN) {
            getApp().comm.sendMessage(["some test", "Lorem ipsum"]);
            System.println("key down.");
            return true;
        }
        System.println("onKey()" + keyEvent.getKey());
        return false;
    }

}