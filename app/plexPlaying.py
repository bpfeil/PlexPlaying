'''
Uses Plex API to get what is being watched and alerts user via PushBullet.
Has ability to ingore specified users.
Logs data to MySQL server.

Ben Pfeil
Initial release 12/28/2014
R2        2/24/2015     -    Logging to MySQL for analytics
                              -    Removed writing to directory for status
                              -    Added ability to run multiple server checks through same script
R2.1      3/1/2015      -    Changed mySQL insert commands to prevent auto_incrementing of PK
                              -    Enhanced error handling
R2.2      3/9/2015      -    Converted all fields from DB and Plex to Unicode
R2.3      3/15/2015     -    Corrected where multiple file paths exist in DB for a media file
R2.3.1    4/12/2015    -    Added ability to have a Plex Token in the URL
R2.3.1.1 10/25/2015   -    Changed SQL for device insert and update due to plex changing product definitions 
'''

import mysql.connector
from mysql.connector import Error
from datetime import date, datetime, timedelta
import os, sys, logging
import xml.dom.minidom
import urllib

#URL for plex
ServerList = []
Server = {}
Server['URL'] = 'http://SERVER_URL.com:32400'
Server['Token'] = 'PLEX_TOKEN' #https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
Server['Ignored'] = ['PLEX_USER','ignored']
Server['PB_API'] = 'PUSHBULLET_API'
ServerList.append(Server)

#Log file
logFile = '../Log.log'

#MySQL Stuff
config = {
  'user': 'PlexPlayUpdate',
  'password': 'PlexPlayingUpdater',
  'host': '127.0.0.1', #MYSQL SERVER URL
  'database': 'plexPlaying',
  'raise_on_warnings': True,
}

#Write log to file
logging.basicConfig(filename= logFile, format='%(asctime)s - %(levelname)s : %(message)s', 
     datefmt='%m/%d/%Y %I:%M:%S %p', level=logging.INFO)
info = logging.info
error = logging.error
warn = logging.warn
logging.getLogger().addHandler(logging.StreamHandler())

def InsertWatching(user, video, player, mediaFile, platform, product, server):
     #Insert item being watched
     try:
          con = mysql.connector.connect(**config)
          cursor = con.cursor()
          
          now = datetime.now()
          
          add_user = ("INSERT INTO plexUsers "
                    "(UserName) "
                    "SELECT %s "
                    "FROM (select 1) as a "
                    "WHERE NOT EXISTS( "
                         "SELECT UserName "
                         "FROM plexUsers "
                         "WHERE UserName = %s) "
                    "Limit 1")
          add_Server = ("INSERT INTO plexServer "
                    "(ServerName, ServerURL) "
                    "SELECT %s, %s "
                    "FROM (select 1) as a "
                    "WHERE NOT EXISTS( "
                         "SELECT ServerName, ServerURL "
                         "FROM plexServer "
                         "WHERE ServerName = %s AND ServerURL = %s) "
                    "Limit 1")
          add_Device = ("INSERT INTO Device "
                    "(idUser, DeviceName, Platform) "
                    "SELECT %s, %s, %s "
                    "FROM (select 1) as a "
                    "WHERE NOT EXISTS( "
                         "SELECT idUser, DeviceName, Platform "
                         "FROM Device "
                         "WHERE idUser = %s AND DeviceName = %s AND Platform = %s) "
                    "Limit 1")
          add_MediaFile = ("INSERT INTO MediaFile "
                    "(MediaFileName, MediaFilePath, idServer) "
                    "SELECT %s, %s, %s "
                    "FROM (select 1) as a "
                    "WHERE NOT EXISTS( "
                         "SELECT MediaFileName, MediaFilePath, idServer "
                         "FROM MediaFile "
                         "WHERE MediaFileName = %s AND MediaFilePath = %s AND idServer = %s) "
                    "Limit 1")
          add_watchedStart = ("INSERT INTO watchedItem "
                    "(idUser, Start_Time, ShowID, idDevice, idServer) "
                    "SELECT %s, %s, %s, %s, %s "
                    "FROM (select 1) as a "
                    "WHERE NOT EXISTS( "
                         "SELECT idUser, Start_Time, ShowID, idDevice, idServer "
                         "FROM watchedItem "
                         "WHERE idUser = %s AND Start_Time = %s AND ShowID = %s AND idDevice = %s AND idServer = %s) "
                    "Limit 1")
          
          #Insert user data
          data_user = (user, user)
          cursor.execute(add_user, data_user)
          user_no = cursor.lastrowid
          info("User_no {}".format(user_no))
          if (user_no == 0):
               warn("User already exists for {}".format(user))
               cursor.execute("Select idUser FROM plexPlaying.plexUsers WHERE UserName = %s", (user,))
               for (item) in cursor:
                    user_no = "%i" % item
                    info("Updated user # to {}".format(item))
          
          #Insert server data
          data_Server = (server['Name'], server['URL'], server['Name'], server['URL'])
          cursor.execute(add_Server, data_Server)
          server_no = cursor.lastrowid
          info("Server_no {}".format(server_no))
          if (server_no == 0):
               warn("Server already exists for {}".format(server['Name']))
               cursor.execute("Select idServer FROM plexPlaying.plexServer WHERE ServerName = %s", (server['Name'],))
               for (item) in cursor:
                    server_no = "%i" % item
                    info("Updated server # to {}".format(item))
          
          #Insert device data
          data_device = (user_no, player, platform, user_no, player, platform)
          cursor.execute(add_Device, data_device)
          device_no = cursor.lastrowid
          info("Device_no {}".format(device_no))
          if (device_no == 0):
               warn("Device already exists for {}".format(player))
               info("Checking if data is missing")
               cursor.execute("UPDATE plexPlaying.Device SET Platform = %s, Product = %s WHERE idUser = %s AND DeviceName = %s AND Product != %s", (platform, product, user_no, player, product))
               cursor.execute("Select idDevice FROM plexPlaying.Device WHERE DeviceName = %s AND idUser = %s", (player, user_no))
               for (item) in cursor:
                    device_no = "%i" % item
                    info("Updated device # to {}".format(item))
          
          #Insert media data
          data_mediaFile = (video, mediaFile, server_no, video, mediaFile, server_no)
          cursor.execute(add_MediaFile, data_mediaFile)
          mediaFile_no = cursor.lastrowid
          info("MediaFile_no {}".format(mediaFile_no)) 
          if (mediaFile_no == 0):
               warn("MediaFile already exists for {}".format(mediaFile))
               cursor.execute("Select idMediaFile FROM plexPlaying.MediaFile WHERE MediaFileName = %s AND idServer = %s", (video, server_no))
               for (item) in cursor:
                    mediaFile_no = "%i" % item
                    info("Updated mediaFile # to {}".format(item))
          
          #Insert into watched table
          data_watched = (user_no, now, mediaFile_no, device_no, server_no, user_no, now, mediaFile_no, device_no, server_no)
          cursor.execute(add_watchedStart, data_watched)
          watched_no = cursor.lastrowid
          print watched_no
     
          con.commit()
     
     except mysql.connector.Error as e:
          error('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
          error("Error code: {}".format(e.errno))        # error number
          error("SQLSTATE value: {}".format(e.sqlstate)) # SQLSTATE value
          error("Error message: {}".format(e.msg))      # error message
          
     except Error as e:
          error('Error: {}'.format(e))
          
     finally:
          cursor.close()
          if con:
               con.close()
               
def insertStop(user, video, player, mediaFile, serverID):
     #End item that is being watched in DB
     try:
          con = mysql.connector.connect(**config)
          cursor = con.cursor()
          
          now = datetime.now()
          
          update_watchedStop = ("UPDATE watchedItem "
                    "SET End_Time = %s "
                    "WHERE idUser = %s AND ShowID = %s AND idDevice = %s AND End_Time is NULL")

          cursor.execute("Select idUser FROM plexPlaying.plexUsers WHERE UserName = %s", (user,))
          for (item) in cursor:
               user_no = "%i" % item 
          cursor.execute("Select idDevice FROM plexPlaying.Device WHERE DeviceName = %s AND idUser = %s", (player, user_no))
          for (item) in cursor:
               device_no = "%i" % item
          cursor.execute("Select idMediaFile FROM plexPlaying.MediaFile WHERE MediaFileName = %s AND MediaFilePath = %s AND idServer = %s", (video, mediaFile, serverID))
          for (item) in cursor:
               mediaFile_no = "%i" % item
          data_watched = (now, user_no, mediaFile_no, device_no)
          cursor.execute(update_watchedStop, data_watched)
          watched_no = cursor.lastrowid
     
          con.commit()
          
     except mysql.connector.Error as e:
          error('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
          error("Error code: {}".format(e.errno))        # error number
          error("SQLSTATE value: {}".format(e.sqlstate)) # SQLSTATE value
          error("Error message: {}".format(e.msg))      # error message
          
     except Error as e:
          error('Error: {}'.format(e))

     finally:
          cursor.close()
          if con:
               con.close()

def currentPlaying(server):
     #Get what is currently being played from DB
     try:
          con = mysql.connector.connect(**config)
          cursor = con.cursor()
          
          watching = ("Select UserName, MediaFileName, MediaFilePath, DeviceName "
                    "FROM plexPlaying.watchedItem "
                    "LEFT JOIN plexPlaying.MediaFile ON plexPlaying.watchedItem.ShowID = plexPlaying.MediaFile.idMediaFile "
                    "LEFT JOIN plexPlaying.Device ON plexPlaying.watchedItem.idDevice = plexPlaying.Device.idDevice "
                    "LEFT JOIN plexPlaying.plexUsers ON plexPlaying.watchedItem.idUser = plexPlaying.plexUsers.idUser "
                    "WHERE End_Time is NULL AND plexPlaying.watchedItem.idServer = %s")
          
          server_id = ("Select idServer "
                    "From plexPlaying.plexServer "
                    "Where ServerName = %s")
          
          cursor.execute(server_id, (server,))
          for item in cursor:
               server_id = item
          cursor.execute(watching, server_id)
          
          watching = []
          
          for (item) in cursor:
               playing = {}
               playing['video'] = item[1].encode('utf-8')
               playing['user'] = item[0].encode('utf-8')
               playing['mediaFile'] = item[2].encode('utf-8')
               playing['player'] = item[3].encode('utf-8')
               
               watching.append(playing)
          
          return watching
          
     except mysql.connector.Error as e:
          error('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
          error("Error code: {}".format(e.errno))        # error number
          error("SQLSTATE value: {}".format(e.sqlstate)) # SQLSTATE value
          error("Error message: {}".format(e.msg))      # error message
          return False
          
     except Error as e:
          error('Error: {}'.format(e))

     finally:
          cursor.close()
          if con:
               con.close()

def getServerID(serverName):
     #Retrieve serverID from DB
     try:
          con = mysql.connector.connect(**config)
          cursor = con.cursor()
          
          server_id = ("Select idServer "
                    "From plexPlaying.plexServer "
                    "Where ServerName = %s")
     
          cursor.execute(server_id, (serverName,))
          
          for item in cursor:
               return item[0]
     
     except mysql.connector.Error as e:
          error('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
          error("Error code: {}".format(e.errno))        # error number
          error("SQLSTATE value: {}".format(e.sqlstate)) # SQLSTATE value
          error("Error message: {}".format(e.msg))      # error message
          
     except Error as e:
          error('Error: {}'.format(e))
          
     finally:
          cursor.close()
          if con:
               con.close()

def getServerInfo(devicePath):
     #Get server name from Plex Server
     try:
          url = devicePath + '/servers'
          data = urllib.urlopen(url)
          if data.getcode() == 404:
               raise Exception("404 response from {}".format(url))
          else:
               xml_str = data.read()
               
          # Open XML document using minidom parser
          DOMTree = xml.dom.minidom.parseString(xml_str)
          mediaContainer = DOMTree.documentElement

          name = mediaContainer.getElementsByTagName("Server")[0].attributes['name'].value
          
          return name
          
     except Exception,e:
          exc_type, exc_obj, exc_tb = sys.exc_info()
          warn('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
          warn(str(e))
          return False

def getPlaying(Server, Token):
     #Read Plex API and get what's playing and who's watching
     try:
          if Token:
               url = Server + '/status/sessions?X-Plex-Token=' + Token
          else:
               url = Server + '/status/sessions'
          data = urllib.urlopen(url)
          if data.getcode() == 404:
               raise Exception("404 response from {}".format(url))
          else:
               xml_str = data.read()

          # Open XML document using minidom parser
          DOMTree = xml.dom.minidom.parseString(xml_str)
          mediaContainer = DOMTree.documentElement

          videos = mediaContainer.getElementsByTagName("Video")
          #tracks = mediaContainer.getElementsByTagName("Track")   - If wanting to look at music playback someday
          
          nowPlaying = []
          
          for video in videos:
               playing = {}
               user = video.getElementsByTagName('User')[0].attributes['title'].value
               player = video.getElementsByTagName("Player")[0].attributes["title"].value
               player_platform = video.getElementsByTagName("Player")[0].attributes["platform"].value
               player_product = video.getElementsByTagName("Player")[0].attributes["product"].value
               mediaFile = video.getElementsByTagName("Media")[0].getElementsByTagName("Part")[0].attributes["file"].value

               type = video.attributes["type"].value
               
               if type == 'episode':
                    show = video.attributes["grandparentTitle"].value
                    video = video.attributes["title"].value
                    video = show + " (" + video + ")"
               elif type == 'movie':
                    video = video.attributes["title"].value
               elif type == 'clip':
                    print "Clip is being watched"
                    break
               
               #ensure we're looking at unicode text
               video = video.encode('utf-8')
               user = user.encode('utf-8')
               mediaFile = mediaFile.encode('utf-8')
               player = player.encode('utf-8')
               player_platform = player_platform.encode('utf-8')
               player_product = player_product.encode('utf-8')
               
               
               playing['video'] = video
               playing['user'] = user
               playing['mediaFile'] = mediaFile
               playing['player'] = player
               playing['player_platform'] = player_platform
               playing['player_product'] = player_product
               
               nowPlaying.append(playing)
               
          return nowPlaying
     
     except Exception,e:
          exc_type, exc_obj, exc_tb = sys.exc_info()
          warn('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))
          warn(str(e))
          return False

def checkWatchingDB(DB_File, URL_File, server):
     #compare DB and Plex watching records
     serverID = getServerID(server['Name'])
     for db_item in DB_File[:]:
          for playing in URL_File[:]:
               if db_item['video'] == playing['video']:
                    if db_item['user'] == playing['user']:
                         if db_item['player'] == playing['player']:
                              info("{} - Still watching {} - {} on {}".format(server['Name'], playing['video'], playing['user'], playing['player']))
                              URL_File.remove(playing)
                              DB_File.remove(db_item)
                              continue
                         else:
                              info("Player doesn't match")
                    else:
                         info("User doesn't match")
               else:
                    info("Video doesn't match")
     
     #update what we are watching
     for item in URL_File:
          InsertWatching(item['user'], item['video'], item['player'], item['mediaFile'], item['player_platform'], item['player_product'], server)
          pbMessage =   "'{} is being watched by {}'".format(item['video'], item['user'])
          pbAlert(item['user'], pbMessage, server)
          
     #remove what is done
     for db_item in DB_File:
          removeWatching(db_item, server)

def removeWatching(done_Watching, server):
     #Helper function to remove what is being watched
     serverID = getServerID(server['Name'])
     #print done_Watching
     beingWatched = "{} - {} ({})".format(done_Watching['user'], done_Watching['video'], done_Watching['player'])
     
     info("No longer watching {}".format(beingWatched))
     info("Removing {}".format(beingWatched))
     pbMessage = "'{} is no longer being watched'".format(beingWatched)
     pbAlert(done_Watching['user'], pbMessage, server)
     insertStop(done_Watching['user'], done_Watching['video'], done_Watching['player'], done_Watching['mediaFile'], serverID)

def pbAlert(user, message, server):
     #Send alert via Pushbullet
     API = server['PB_API']
     if user not in server['Ignored']:
          info("***Pushbullet Alert***")
          info(message)
          info("****PushBullet End****")
          os.system('bash pushbullet_API.sh ' + API + ' ' + message)
     else:
          info("User ({}) is in ignore file.  Not updating via PushBullet".format(user))
    
def main():
     # Get information for each server
     for server in ServerList:
          #Get serverName from Plex Server
          server['Name'] = getServerInfo(server['URL'])
          if server['Name'] == False:
               warn("Unable to reach server at {}".format(server['URL']))
               currentWatching = False
          else:
               #Get what DB says is currently being watched
               currentWatching = currentPlaying(server['Name'])
          
          #Get now playing from Plex Server
          nowPlaying = getPlaying(server['URL'], server['Token'])
          if nowPlaying:
               info("{} - {} Items being watched".format(server['Name'], len(nowPlaying)))
          else:
               info(" {} - 0 Items being watched".format(server['Name'],))
          
          if (currentWatching) == False:
               #Handle if there are no entries in DB
               error("{} - Nothing in currently in DB".format(server['Name']))
               if nowPlaying != False:
                    for item in nowPlaying:
                         InsertWatching(item['user'], item['video'], item['player'], item['mediaFile'], item['player_platform'], item['player_product'], server)
                         pbMessage =   "'{} is being watched by {}'".format(item['video'], item['user'])
                         pbAlert(item['user'], pbMessage, server)
          #Handle if we cannot find Plex server
          elif (nowPlaying) == False:
               error("{} - No connection to plexServer".format(server['Name']))
          else:
               #validate what is playing vs. DB
               checkWatchingDB(currentWatching, nowPlaying, server)
     
if __name__ == "__main__":
   main()
