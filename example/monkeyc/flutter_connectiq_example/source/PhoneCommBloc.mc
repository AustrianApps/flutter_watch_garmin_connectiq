using Toybox.Communications;

class PhoneCommBloc {
    private var commListener = new CommListener();

    public function initialize() {
        Communications.registerForPhoneAppMessages(method(:phoneMessageReceived));
    }

    function phoneMessageReceived(msg as Communications.Message) as Void {
        System.println("received message: " + msg);
    }

    function sendMessage(msg) as Void {
        Communications.transmit(msg, null, commListener);
    }
}

//! Handles the completion of communication operations
class CommListener extends Communications.ConnectionListener {

    //! Constructor
    public function initialize() {
        Communications.ConnectionListener.initialize();
    }

    //! Handle a communications operation completing
    public function onComplete() as Void {
        System.println("Transmit Complete");
    }

    //! Handle a communications operation erroring
    public function onError() as Void {
        System.println("Transmit Failed");
    }
}
