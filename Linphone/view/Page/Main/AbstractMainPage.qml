/**
* Qml template used for overview pages : Calls, Contacts, Conversations, Meetings, Settings
**/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Control

import Linphone
import UtilsCpp
import 'qrc:/qt/qml/Linphone/view/Style/buttonStyle.js' as ButtonStyle
import "qrc:/qt/qml/Linphone/view/Control/Tool/Helper/utils.js" as Utils

FocusScope {
	id: mainItem
	property string noItemButtonText
	property string newItemIconSource
	property string emptyListText
	property bool showDefaultItem: true
	property color rightPanelColor: DefaultStyle.grey_100
	property alias leftPanelContent: leftPanel.children
	property alias rightPanelStackView: rightPanelStackView
	property alias rightPanel: rightPanel
	property int rightPanelStackTopMargin: 0
	property int rightPanelStackBottomMargin: 0
	signal noItemButtonPressed()

	// Phone: list and detail are shown one at a time. Pages call openDetail() when the user
	// picks an item; the back button in the detail view returns to the list.
	property bool detailOpen: false
	readonly property bool mobileListOnly: DefaultStyle.mobile && !detailOpen
	readonly property bool mobileDetailOnly: DefaultStyle.mobile && detailOpen
	// The detail view has its own back button (chat header): no back bar above it.
	property bool mobileOwnBackButton: false
	onMobileDetailOnlyChanged: DefaultStyle.mobileDetailShown = mobileDetailOnly
	signal detailClosed()
	function openDetail() {
		if (DefaultStyle.mobile) detailOpen = true
	}
	function closeDetail() {
		// Phone: a field of the detail view (chat message) keeps the focus and the keyboard otherwise
		if (DefaultStyle.mobile) {
			Qt.inputMethod.hide()
			mainItem.forceActiveFocus()
		}
		detailOpen = false
		detailClosed()
	}
	onVisibleChanged: if (!visible) detailOpen = false

	Control.SplitView {
		id: splitView
		anchors.fill: parent
    	anchors.topMargin: DefaultStyle.mobile ? 0 : Utils.getSizeWithScreenRatio(10)

		handle: Rectangle {
    		implicitWidth: DefaultStyle.mobile ? 0 : Utils.getSizeWithScreenRatio(6)
			color: Control.SplitHandle.hovered ? DefaultStyle.main2_200 : DefaultStyle.grey_200
		}
		ColumnLayout {
			id: leftPanel
			spacing:0
			// Control.SplitView.fillWidth:false
			Control.SplitView.fillHeight: true
			visible: !mainItem.mobileDetailOnly
			Control.SplitView.fillWidth: mainItem.mobileListOnly
			Control.SplitView.preferredWidth: DefaultStyle.mobile ? splitView.width : Utils.getSizeWithScreenRatio(404)
    		Control.SplitView.minimumWidth: DefaultStyle.mobile ? 0 : Utils.getSizeWithScreenRatio(200)
    		Control.SplitView.maximumWidth: DefaultStyle.mobile ? Number.POSITIVE_INFINITY : Utils.getSizeWithScreenRatio(500)
		}
		Rectangle {
			id: rightPanel
			clip: true
			color: mainItem.rightPanelColor
			visible: !mainItem.mobileListOnly
			Control.SplitView.fillWidth: !mainItem.mobileListOnly
			Control.SplitView.fillHeight: true

			RowLayout {
				id: mobileBackBar
				// Pages pushed above the detail (meeting or contact edition) have their own back button
				visible: mainItem.mobileDetailOnly && !mainItem.mobileOwnBackButton && rightPanelStackView.depth <= 1
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				height: visible ? Utils.getSizeWithScreenRatio(44) : 0
				Button {
					style: ButtonStyle.noBackgroundOrange
					icon.source: AppIcons.leftArrow
					Layout.leftMargin: Utils.getSizeWithScreenRatio(8)
					Layout.preferredWidth: Utils.getSizeWithScreenRatio(40)
					Layout.preferredHeight: Utils.getSizeWithScreenRatio(40)
					icon.width: Utils.getSizeWithScreenRatio(24)
					icon.height: Utils.getSizeWithScreenRatio(24)
					//: Return
					Accessible.name: qsTr("return_accessible_name")
					onClicked: mainItem.closeDetail()
				}
				Item { Layout.fillWidth: true }
			}

			StackLayout {
				currentIndex: mainItem.showDefaultItem ? 0 : 1
				anchors.fill: parent
				anchors.topMargin: mobileBackBar.visible ? mobileBackBar.height : 0
				ColumnLayout {
					id: defaultItem
					
					RowLayout {
						Layout.alignment: Qt.AlignHCenter
						Item {
							Layout.fillWidth: true
						}
						ColumnLayout {
                            spacing: Utils.getSizeWithScreenRatio(30)
							Item {
								Layout.fillHeight: true
							}
							Image {
								Layout.alignment: Qt.AlignHCenter
								source: AppIcons.noItemImage
                                Layout.preferredWidth: Utils.getSizeWithScreenRatio(359)
                                Layout.preferredHeight: Utils.getSizeWithScreenRatio(314)
								fillMode: Image.PreserveAspectFit
							}
							Text {
								text: mainItem.emptyListText
								Layout.alignment: Qt.AlignHCenter
								font {
                                    pixelSize: Typography.h3.pixelSize
                                    weight: Typography.h3.weight
								}
							}
							BigButton {
								Layout.alignment: Qt.AlignHCenter
								icon.source: mainItem.newItemIconSource
								style: ButtonStyle.main
								text: mainItem.noItemButtonText
                                spacing: Utils.getSizeWithScreenRatio(8)
								onPressed: mainItem.noItemButtonPressed()
							}
							Item {
								Layout.fillHeight: true
							}
						}
						Item {
							Layout.fillWidth: true
						}
					}
					
				}
				Control.StackView {
					id: rightPanelStackView
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.topMargin: mainItem.rightPanelStackTopMargin
					Layout.bottomMargin: mainItem.rightPanelStackBottomMargin
					visible: false
				}
			}
		}
	}
}
