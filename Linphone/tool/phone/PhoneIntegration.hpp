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

#ifndef PHONE_INTEGRATION_H_
#define PHONE_INTEGRATION_H_

#include <QObject>

class QWindow;
class AboveLockscreen;

// Phone shell integration (Plasma Mobile and other Linux desktops):
// - show the calls window above the lock screen (KDE kde_lockscreen_overlay_v1, needs
//   X-KDE-Wayland-Interfaces=kde_lockscreen_overlay_v1 in the desktop file);
// - turn the screen on for an incoming call;
// - keep the session from locking and blanking the screen while a call is running.
// Every part is a no-op where the platform does not provide it.
class PhoneIntegration : public QObject {
	Q_OBJECT
public:
	static PhoneIntegration *getInstance();

	// Must be called right after show(): KWin looks up the window by its surface, so the toplevel must exist,
	// and the surface must not be mapped yet (no buffer committed), or the compositor raises a protocol error.
	void allowAboveLockscreen(QWindow *window);
	// Thread safe.
	static void wakeScreen();
	void setCallActive(bool active);

private:
	explicit PhoneIntegration(QObject *parent = nullptr);

	AboveLockscreen *mAboveLockscreen = nullptr;
	bool mAboveLockscreenTried = false;
	bool mInhibited = false;
	uint mInhibitCookie = 0;
};

#endif
