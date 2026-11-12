/*
 * This file is part of linphone-desktop
 * (see https://www.linphone.org).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "PhoneIntegration.hpp"

#include <QGuiApplication>
#include <QProcess>
#include <QStandardPaths>
#include <QWindow>
#ifdef QT_DBUS_LIB
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusReply>
#endif

#include "config.h"
#include "tool/Utils.hpp"

#ifdef LINPHONE_WAYLAND_LOCKSCREEN_OVERLAY
#include <QtGui/qpa/qplatformnativeinterface.h>
#include <QtWaylandClient/QWaylandClientExtension>

#include "qwayland-kde-lockscreen-overlay-v1.h"

class AboveLockscreen : public QWaylandClientExtensionTemplate<AboveLockscreen>,
                        public QtWayland::kde_lockscreen_overlay_v1 {
public:
	AboveLockscreen() : QWaylandClientExtensionTemplate<AboveLockscreen>(1) {
		initialize();
	}
	~AboveLockscreen() {
		if (isInitialized()) destroy();
	}
};
#else
class AboveLockscreen {};
#endif

PhoneIntegration::PhoneIntegration(QObject *parent) : QObject(parent) {
}

PhoneIntegration *PhoneIntegration::getInstance() {
	static PhoneIntegration *instance = new PhoneIntegration(qApp);
	return instance;
}

void PhoneIntegration::allowAboveLockscreen(QWindow *window) {
#ifdef LINPHONE_WAYLAND_LOCKSCREEN_OVERLAY
	if (!window || !QGuiApplication::platformName().startsWith(QLatin1String("wayland"))) return;
	if (!mAboveLockscreenTried) {
		mAboveLockscreenTried = true;
		mAboveLockscreen = new AboveLockscreen();
	}
	if (!mAboveLockscreen || !mAboveLockscreen->isActive()) {
		lInfo() << "[PhoneIntegration] kde_lockscreen_overlay_v1 not available, calls window stays below the lock "
		           "screen";
		return;
	}
	auto surface = static_cast<struct ::wl_surface *>(
	    QGuiApplication::platformNativeInterface()->nativeResourceForWindow("surface", window));
	if (!surface) {
		lWarning() << "[PhoneIntegration] no wl_surface for the calls window";
		return;
	}
	mAboveLockscreen->allow(surface);
	lInfo() << "[PhoneIntegration] calls window allowed above the lock screen";
#else
	Q_UNUSED(window)
#endif
}

void PhoneIntegration::wakeScreen() {
#ifdef Q_OS_LINUX
	// KWin: same as any input event, the outputs are powered back on.
	static const QString kscreenDoctor = QStandardPaths::findExecutable(QStringLiteral("kscreen-doctor"));
	if (kscreenDoctor.isEmpty()) return;
	QProcess::startDetached(kscreenDoctor, {QStringLiteral("--dpms"), QStringLiteral("on")});
#endif
}

void PhoneIntegration::setCallActive(bool active) {
#ifdef QT_DBUS_LIB
	if (active == mInhibited) return;
	auto bus = QDBusConnection::sessionBus();
	if (active) {
		auto msg = QDBusMessage::createMethodCall(
		    QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("/ScreenSaver"),
		    QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("Inhibit"));
		msg << QStringLiteral(EXECUTABLE_NAME) << QStringLiteral("Call in progress");
		QDBusReply<uint> reply = bus.call(msg, QDBus::Block, 2000);
		if (reply.isValid()) {
			mInhibitCookie = reply.value();
			mInhibited = true;
			lInfo() << "[PhoneIntegration] screen lock inhibited during the call";
		} else {
			lWarning() << "[PhoneIntegration] cannot inhibit screen lock:" << reply.error().message();
		}
	} else {
		auto msg = QDBusMessage::createMethodCall(
		    QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("/ScreenSaver"),
		    QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("UnInhibit"));
		msg << mInhibitCookie;
		bus.call(msg, QDBus::NoBlock);
		mInhibited = false;
		lInfo() << "[PhoneIntegration] screen lock allowed again";
	}
#else
	Q_UNUSED(active)
#endif
}
