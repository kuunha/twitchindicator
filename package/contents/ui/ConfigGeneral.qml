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
            // settings.forceDarkMode: true
            // settings.javascriptEnabled : true
            // settings.localStorageEnabled : true

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
            // webView.url = "https://duckduckgo.com/?q=useragent"
            webView.url = "https://id.twitch.tv/oauth2/authorize?client_id=yoilemo3cudfjaqm6ukbew2g2mgm2v&redirect_uri=http://localhost&response_type=token&scope=user%3Aread%3Afollows";
        }
    }

    function rerelogin() {
        Qt.openUrlExternally("http://localhost/#access_token=123")
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
                id: alttoken
                text: "Twitch access token #2"
            }
            Button {
                text: "Relogin"
                onClicked: {
                    rerelogin();
                }
            }
        }

        RowLayout {
            Label {
                id: tokenlbl
                text: "Current token: " + plasmoid.configuration.twitchToken
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
