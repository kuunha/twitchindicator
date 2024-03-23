import QtQuick
import org.kde.kirigami as Kirigami

MouseArea {
    height: 42
    width: 42
    property alias icon: image.source 

    Kirigami.Icon {
        id: image
        anchors.fill: parent
    }
}
