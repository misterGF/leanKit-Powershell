Get Kanban Snapshot from leankit
===============

### Download snapshot of progress from leankit

This script is meant to download a snapshot of your kanban board from leankit.
It uses web automation to login and navigate the site. Then clicks the link that generates
the snapshot. Once clicked it requieres WASP to click on the "Save" button the IE presents.

It saves it to your download folder under the default naming scheme (board_xxxx.png). The script
removes old entries by default. Can comment out if you choice too.

Make sure you keep the WASP.dll in the same directory. Required powershell v2+
The boardID can be found in the URL when you are logged in to your leankit account.

**Syntax Example** :

> ./get-kanbanSnapShot.ps1 -userName "gil@myEmail.com" -password "Super!Secure!" -leankitURL "myBoard.leankit.com" -boardID "100201"

Last modified May 22 2014 by GF