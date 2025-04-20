import QtQuick
import QtQuick.Window
import QtWebEngine
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: generalSettings

    property alias cfg_updateInterval: updateTime.value
    property alias cfg_twitchToken: authFlow.cfg_twitchToken

    Window {
        id: authFlow
        visible: false
        height: 600
        width: 800
        property string cfg_twitchToken: ""

        WebEngineView {
            id: webView
            anchors.fill: parent
            profile: WebEngineProfile {
                httpAcceptLanguage : "en"
                offTheRecord: true
            }
            onUrlChanged: {
                if (webView.url.toString().startsWith("http://localhost")) { //success
                    let tokenData = webView.url.toString().replace("http://localhost/#access_token=", "");
                    let idTokenStart = tokenData.indexOf("&");
                    let token = tokenData.substring(0, idTokenStart);
                    authFlow.cfg_twitchToken = token;
                    authFlow.visible = false;
                    console.log("New token: "+token);
                }
            }
        }

        function relogin() {
            if (!authFlow.visible) authFlow.show();
            webView.url = "https://id.twitch.tv/oauth2/authorize?client_id=yoilemo3cudfjaqm6ukbew2g2mgm2v&redirect_uri=http://localhost&response_type=token&scope=user%3Aread%3Afollows";
        }
    }

    ColumnLayout {
        anchors.right: parent.right
        anchors.left: parent.left

        RowLayout {
            Label {
                id: token
                text: "Twitch access token"
            }
            Button {
                text: "Relogin"
                onClicked: {
                    authFlow.relogin();
                }
            }
        }

        RowLayout {
		    Label {
			    text: "Update every"
		    }
		    SpinBox {
			    id: updateTime
			    from: 1
			    stepSize: 1
			    to: 60
			    textFromValue: (value, locale) => {
                    return value + " min";
                }
		    }
	    }
    }
}
