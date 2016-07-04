import threading, os

print "Starting now......"
count = 1

def runIt():
  threading.Timer(30.0, runIt).start()
  global count
  print "-----Running for {} time-----".format(count)
  os.system("python plexPlaying.py")
  print "-----Done running for {} time-----".format(count)
  count += 1
  

runIt()

# continue with the rest of your code