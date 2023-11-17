Utilities for searching all DHCP Servers.

The batch file offers an interactive interface with 
basic functionality, or direct access to the
powershell scripts can be taken advantage of.
==========================================================
|            Instructions:                               |
==========================================================

Run the .bat file "MAC)HunteR.bat" with DHCP administrator privileges,
and follow the instructions.

"servers.txt"
---------------------------
List all DHCP servers here, separated by a newline each.

"MAC_HunteR.bat"
---------------------------
Prompts the user to paste in a list of MAC addresses from the clipboard.
This takes a MAC address in the format XXXX.XXXX.XXXX, which is incidentally 
the format outputted by "show access-session" and "show mac address-table"
on cisco IOS switches.

Highlight the outputted lines in the SSH (Kitty or Putty etc...) terminal
and then simply press Enter in the console window from this
program and it'll run the DHCP search on all those addresses from the IOS
terminal.

The DHCP leases associated with those MACs will be listed in the terminal window
next to the switch port number, if it was listed on the same line as the MAC
in the copied text.

The user can also just type in a single regex string for searching
a MAC across all the servers in the format XX-XX-XX-XX-XX-XX.

**BUG**: i couldn't find a way to make the HostName field longer

===========================================================
|            How does it work?                            |
===========================================================
The batch file just launch the .ps1 scripts.
The .ps1 scripts themselves have multiple useful parameters and are self documenting!

By default,
a single download request of all the leases on all the servers for all scopes is made
and then the data is searched sequentially offline for the MACs with powershell regex.

----- Last updated by Sean Bikkes 18/10/2023 -----