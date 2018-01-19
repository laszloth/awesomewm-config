#!/usr/bin/env python

import dbus
import gobject
from dbus.mainloop.glib import DBusGMainLoop
from dbus.exceptions import DBusException

spotify_bus_name = "org.mpris.MediaPlayer2.spotify"
spotify_object_path = "/org/mpris/MediaPlayer2"
awesome_bus_name = "org.awesomewm.awful"
awesome_object_path = "/"

class SpotifyProxy(object):

    def __init__(self):
        bus_loop = DBusGMainLoop(set_as_default=True)
        self.session_bus = dbus.SessionBus(mainloop=bus_loop)

        #self.spotify_props_if = dbus.Interface(spotify_proxy, "org.freedesktop.DBus.Properties")

        self.awesome_proxy = None
        self.awesome_remote_if = None
        self.dbus_proxy = None
        self.spotify_proxy = None

        self.connectToAwesome()
        self.connectToDBus()

        try:
            self.connectToSpotify()
        except DBusException, e:
            #err = e.get_dbus_message()
            #print "failed to connect to Spotify: {0}".format(err)
            self.sendEvent("mp_quit", None)

        gobject.MainLoop().run()

    def PropertiesChanged_handler(self, interface, changed, invalidated):
        pbstatus = changed.get("PlaybackStatus", {})
        '''metadata = changed.get("Metadata", {})
        if metadata:
            for key, value in metadata.items():
                print key, value
        '''
        self.sendEvent("mp_stat", pbstatus)

    def sendEvent(self, event, data, tried=False):
        try:
            if data:
                self.awesome_remote_if.Eval('ext_event_handler("{0}", "{1}")'.format(event, data))
            else:
                self.awesome_remote_if.Eval('ext_event_handler("{0}", nil)'.format(event))
        except DBusException, e:
            # awesome was restarted, reinitalize and send again
            #err = e.get_dbus_message()
            #print "failed to connect to Awesome: {0}".format(err)
            self.awesome_proxy = None
            self.awesome_remote_if = None
            self.connectToAwesome()
            if not tried:
                self.sendEvent(event, data, True)

    def connectToAwesome(self):
        self.awesome_proxy = self.session_bus.get_object(awesome_bus_name, awesome_object_path)
        self.awesome_remote_if = dbus.Interface(self.awesome_proxy, "org.awesomewm.awful.Remote")

    def connectToDBus(self):
        self.dbus_proxy = self.session_bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
        self.dbus_proxy.connect_to_signal("NameOwnerChanged", self.NameOwnerChanged_handler, arg0=spotify_bus_name)

    def connectToSpotify(self):
        self.spotify_proxy = self.session_bus.get_object(spotify_bus_name, spotify_object_path)
        self.spotify_proxy.connect_to_signal("PropertiesChanged", self.PropertiesChanged_handler)

    def NameOwnerChanged_handler(self, name, old_owner, new_owner):
        #print "name owner changed: spotify"
        if new_owner:
            self.connectToSpotify()
        else:
            self.spotify_proxy = None
            self.sendEvent("mp_quit", None)

if __name__ == "__main__":
    SpotifyProxy()
