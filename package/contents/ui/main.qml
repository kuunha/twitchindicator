import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 5

    property int updateInterval: plasmoid.configuration.updateInterval
    property string twitchToken: plasmoid.configuration.twitchToken

    function log(message, values) {
        console.log(message);
        console.log(JSON.stringify(values));
    }

    function requestUrl(method, url, options, cb) {
        let xhr = new XMLHttpRequest();
		xhr.open(method, url, true);
		xhr.onload = function (e) {
            console.log(xhr.status);
            console.log(xhr.responseText);
		    if (xhr.status == 200) {
				let body = xhr.response;
				cb(body);
			}
			else {
				log("Failed to execure the request: status code is not 200", {method: method, url: url, options: options, request: xhr});
			}
		}
		xhr.onerror = function(e) {
			log("Error executing the request: network error", {method: method, url: url, options: options});
            retryConnection.restart();
		}
		if (options.responseType) xhr.responseType = options.responseType;
		if (options.headers) {
		    let headers = Object.keys(options.headers);
		    for (let i = 0; i < headers.length; i++) {
                xhr.setRequestHeader(headers[i], options.headers[headers[i]]);
            }
		}
		xhr.send(options.postData ? options.postData : undefined);
    }

    function twitchRequest(endpoint, callback) {
        if (!twitchToken) return;
        requestUrl("GET", "https://api.twitch.tv/helix/"+endpoint, {
            responseType: "json",
            headers: {
                "Client-ID": "yoilemo3cudfjaqm6ukbew2g2mgm2v",
                "Authorization": "Bearer "+twitchToken
            }
        }, callback);
    }

    ListModel {
        id: streamsModel
        property var followedChannels: {}
        
        function updateChannelsData() {     //TODO: add support of more than 100 follows/channels
            streamsModel.followedChannels = {};
            console.log("Starting update");
            twitchRequest("users", function(res) {
                let userId = res.data[0].id;
                twitchRequest("channels/followed?user_id="+userId+"&first=100", function(res) {
                    let query = [];
                    for (let broadcast of res.data) {
                        query.push("id="+broadcast.broadcaster_id);
                    }
                    twitchRequest("users?"+query.join("&"), function(res) {
                        for (let channel of res.data) streamsModel.followedChannels[channel.id] = channel;
                        streamsModel.updateStreams();
                    });
                });
            });
        }

        function updateStreams() {
            let query = [];
            for (let channelId in streamsModel.followedChannels) query.push("user_id="+channelId);
            twitchRequest("streams?"+query.join("&"), function(res) {
                streamsModel.clear();
                for (let stream of res.data) {
                    streamsModel.append(stream);
                }
            })
        }
    }
    
    
    compactRepresentation: MouseArea {
        Layout.preferredWidth: intRow.implicitWidth
        Layout.minimumWidth: intRow.implicitWidth
        Layout.preferredHeight: 32
        onClicked: root.expanded = !root.expanded;

        Row {
            id: intRow
            anchors.fill: parent
            spacing: 4
            anchors.margins: Kirigami.Units.gridUnit*0.2

            Image {
                id: mainIcon
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: height
                source: "../images/twitch.png"
                opacity: (streamsModel.count==0) ? 0.4 : 0.8
            }

            PlasmaComponents3.Label {
                id: mainCounter
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                text: streamsModel.count
                fontSizeMode: Text.VerticalFit
                font.pixelSize: 300
                minimumPointSize: Kirigami.Theme.smallFont.pointSize
                horizontalAlignment: Text.AlignHCenter
                opacity: (streamsModel.count==0) ? 0.4 : 1
                width: contentWidth+(Kirigami.Units.gridUnit*0.1)
                smooth: true
                wrapMode: Text.NoWrap
                
            }
        }
    }

    preferredRepresentation: compactRepresentation
    
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30
        Layout.preferredHeight: Screen.height * 0.45

        Component {
                id: streamDelegate
                PlasmaComponents3.ItemDelegate {
                    id: streamItem
                    height: Kirigami.Units.gridUnit * 2.8
                    width: parent.width
                    enabled: true
                    // Cannot assign to non-existent property "onContainsMouseChanged"
                    // onContainsMouseChanged: {
                    //     steamsList.currentIndex = (containsMouse) ? index : -1;
                    // }
                    onClicked: {
                        Qt.openUrlExternally("https://www.twitch.tv/"+streamsModel.followedChannels[model.user_id].login)
                    }
            
                    Image {
                        id: channelIcon
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        width: height
                        source: streamsModel.followedChannels[model.user_id].profile_image_url
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: roundedMask
                        }
                    }

                    Rectangle {
                        id: roundedMask
                        anchors.fill: channelIcon
                        radius: 90
                        visible: false
                    }

                    Item {
                        id: channelHeader
                        anchors.left: channelIcon.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        height: parent.height/2

                        PlasmaComponents3.Label {
                            id: viewersCount
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            width: implicitWidth
                            text: model.viewer_count
                        }

                        PlasmaComponents3.Label {
                            id: channelName
                            text: model.user_name
                            elide: Text.ElideRight
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom 
                        }

                        Kirigami.Icon {
                            id: gameIcon
                            source: "media-playback-start"
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: height
                            anchors.left: channelName.right
                            anchors.leftMargin: Kirigami.Units.largeSpacing
                        }

                        PlasmaComponents3.Label {
                            id: gameName
                            text: model.game_name
                            elide: Text.ElideRight
                            anchors.left: gameIcon.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: viewersCount.left
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                        }
                    }

                    PlasmaComponents3.Label {
                        id: streamName
                        anchors.top: channelHeader.bottom
                        anchors.left: channelIcon.right
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        text: model.title
                        elide: Text.ElideRight
                        opacity: 0.6
                    }
                }
            }

        PlasmaComponents3.ScrollView {
            anchors.fill: parent

            ListView {
                id: steamsList
                currentIndex: -1
                delegate: streamDelegate
                model: streamsModel
                anchors.fill: parent
                // PlasmaComponents3.Highlight is not a type
                // highlight: PlasmaComponents3.Highlight { }
            }
        }
        
    }

    Timer {
        interval: root.updateInterval*60000
        repeat: true
        running: true
        onTriggered: streamsModel.updateChannelsData();
    }

    Timer {
        id: retryConnection
        interval: 30000
        repeat: false
        running: false
        onTriggered: streamsModel.updateChannelsData();
    }

    onTwitchTokenChanged: {
        streamsModel.updateChannelsData();
    }

    Component.onCompleted: {
        streamsModel.updateChannelsData();
    }
}
