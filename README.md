# PlexPlaying
Monitor what is playing on your Plex server and log to MySQL

Setup:
Install MySQL
Run creation script for MySQL
  - Creation.sql

Edit configue in plexPlaying.py
  - Server['URL'] = 'http://SERVER_URL.com:32400'
  - Server['Token'] = 'PLEX_TOKEN'
  - Server['Ignored'] = ['PLEX_USER','ignored']
  - Server['PB_API'] = 'PUSHBULLET_API'

Start app.py (default to run every 30 seconds)
