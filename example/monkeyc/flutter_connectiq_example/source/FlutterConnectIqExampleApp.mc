import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FlutterConnectIqExampleApp extends Application.AppBase {

    public var comm as PhoneCommBloc;

    function initialize() {
        AppBase.initialize();
        comm = new PhoneCommBloc();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new flutter_connectiq_exampleView(), new flutter_connectiq_exampleDelegate() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as FlutterConnectIqExampleApp {
    return Application.getApp() as FlutterConnectIqExampleApp;
}