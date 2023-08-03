import Toybox.Lang;
import Toybox.WatchUi;

class flutter_connectiq_exampleDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new flutter_connectiq_exampleMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}