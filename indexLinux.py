import os
import re
import copy
import shutil
import subprocess
import Tkinter
import Tkinter as tk
from Tkinter import *
from ttk import *
from PIL import ImageTk, Image
import logging
from threading import Thread
import threading

#sudo apt-get install python-imaging-tk
#pip install PIL
#sudo pip install Pillow


class PoapHome(tk.Tk):
 
    def __init__(self):
        tk.Tk.__init__(self)
        self.initialize()

    def initialize(self):
        print("Initializing logging component")
        curdir = os.getcwd()
        logfile =curdir+os.path.sep+"basefiles"+os.path.sep+"logs"+os.path.sep+"poap.log"
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)
        self.handler = logging.FileHandler(''+logfile)
        self.handler.setLevel(logging.INFO)
        self.logger.addHandler(self.handler)
        self.logger.info('--starting logging--')
        print("Initalizing form components")
        self.pathsep=os.path.sep
        self.grid()
        #self.configure(bg = 'lightgray')
        self.geometry("620x630+0+0")
        self.resizable(False,False)
        #add menu bar
        topmenu = Menu(self)
        self.config(menu=topmenu)
        fileMenu = Menu(topmenu)  
        topmenu.add_cascade(label="File",menu=fileMenu)   
        fileMenu.add_command(label="Exit",command=self.doNothing)

        #editMenu = Menu(topmenu)
        #topmenu.add_cascade(label="Edit",menu=editMenu)
        #editMenu.add_command(label="Undo",command=self.doNothing)
        self.curntdir = os.getcwd()
        self.platconf = self.curntdir+os.path.sep+"basefiles"+os.path.sep+"platforms.config"
		
        self.nxverconf = self.curntdir+os.path.sep+"basefiles"+os.path.sep+"nxosversions.config"

        helpMenu = Menu(topmenu)
        topmenu.add_cascade(label="Help",menu=helpMenu)
        helpMenu.add_command(label="How To",command=self.openHelpFile)

        self.addIndexPage()

    def doNothing(self):
        self.logger.info("Hey this command does nothing")

    def onFrameConfigurem(self,event):
            '''Reset the scroll region to encompass the inner frame'''
            self.canvas3.configure(scrollregion=self.canvas3.bbox("all")) 

    def openHelpFile(self):
        print("Opens a help file on UI for users to follow steps to use the tool")
        self.logger.info('Opens a help file on UI for users to follow steps to use the tool')
        currfile = self.curntdir+os.path.sep+"basefiles"+os.path.sep+"Readme.txt"
        strline = ''
        window = Toplevel(app) # self -> root
        window.title('Help File')
        window.geometry("600x300+150+150")
        self.canvas3 = tk.Canvas(window, borderwidth=0, background="#e6e6e2") #ffffff
        frame = tk.Frame(self.canvas3,relief=RAISED, background="#e6e6e2")
        vsb = tk.Scrollbar(window, orient="vertical", command=self.canvas3.yview)
        self.canvas3.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
      
        hsb = tk.Scrollbar(window, orient="horizontal", command=self.canvas3.xview)
        self.canvas3.configure(xscrollcommand=hsb.set)
        hsb.pack(side="bottom", fill="x")
        self.canvas3.pack(side="left", fill="both", expand=True)
        self.canvas3.create_window((4,4), window=frame, anchor="nw",tags="frame")
        frame.bind("<Configure>", self.onFrameConfigurem)
        rows = []
        rw = -1
        cc = 0
        with open(currfile) as fo:
            innercontents = fo.readlines()
            for line in innercontents:
               rw = rw +1
               cols = []
               e = Tkinter.Label(frame,text=line, background="#e6e6e2")
               e.grid(row=rw, column=cc, sticky=W)
               cols.append(e)
               rows.append(cols)
        self.logger.info("Lines read are "+strline)
      


    def process_details(self):
        self.logger.info("Processing form details..")
        #here also we need to check if platformval or platformval1 is not none, same for vernxos
        vernxos=''
        platformval=''
        if self.platchk.get() == 1:
           platformval = self.platform1.get()         
        else:
           platformval = self.varb.get()
        if self.verchk.get() == 1:
            vernxos = self.nxosver1.get()
        else:
            vernxos = self.varv.get()
        telnetvar = self.vart.get()
        httpvar = self.varh.get()
        clockvar = self.varc.get()
        hrvar = self.varhr.get()
        minvar = self.varmin.get()
        serialver = self.serialnum.get()
        #dirpath = self.imagedirpath.get()
        licfilepath = self.licensepath.get()
        swithname = self.switchname.get()
        switchpass = self.password.get()
        switchip = self.switchip.get()
        switchmask = self.mask.get()
        switchgw = self.gateway.get()
        timez = self.timezone.get()
        #print "process details  platformval ",platformval,"vernxos ",vernxos
        configstr = {}
        configstr["switchname"] = swithname
        configstr["switchpass"]= switchpass
        configstr["switchip"] = switchip
        configstr["licfilepath"] = licfilepath
        configstr["switchmask"] = switchmask
        configstr["switchgw"] = switchgw
        configstr["telnetvar"] = telnetvar
        configstr["clockvar"] = clockvar
        configstr["timez"] = timez
        configstr["hrvar"] = hrvar
        configstr["minvar"] = minvar
        configstr["httpvar"] = httpvar        
        #print "platform ",platformval," Version ",vernxos," telnet ",telnetvar," http ",httpvar," clockvar",clockvar," minvar",minvar," hrvar",hrvar
        #print "serialver-",serialver," dirpath-",dirpath," swithname-",swithname," switchpass-",switchpass," switchip-",switchip," switchmask-",switchmask
        #print "gateway-",switchgw," timezoney
        self.createConfFile(configstr,serialver)
        self.createNewTclFile(vernxos)
        #self.copyImagesFromDir(dirpath,platformval,vernxos)
        if self.platchk.get() == 1:
             platv1 = self.platform1.get() 
             self.writeToFile(self.platconf,platv1)
        if self.verchk.get() == 1:
             nxosv1 = self.nxosver1.get()
             self.writeToFile(self.nxverconf,nxosv1)
        #self.clearDirectories()
        self.loadinglabel.config(text = "   Task Completed !  ",compound=RIGHT,image=self.checklabphoto)

    def writeToFile(self,filename,content):
        f = open(filename,"a+")
        f.write("\n"+content.strip())
        f.close()
        
    def createConfFile(self,configstr,serialver):
        self.logger.info("Now creating config file ")
        self.logger.info(configstr)
        curdir = os.getcwd()
        filename = curdir+self.pathsep+"toDir"+self.pathsep+"conf_"+serialver+".cfg"
        f = open(filename,"w+")
        f.write("config terminal"+"\n")
        if(configstr.get("switchname")!=None):
            f.write("switchname "+configstr.get("switchname")+"\n")
        if(configstr.get("switchpass")!=None):
            f.write("username admin password "+configstr.get("switchpass")+" role network-admin"+"\n\n")  
        if(configstr.get("switchip")!=None and configstr.get("switchmask")!=None):
            f.write("interface mgmt0"+"\n\n")
            f.write("shut"+"\n")
            f.write("ip address "+configstr.get("switchip")+" "+configstr.get("switchmask")+"\n")
            f.write("ip default-gateway "+configstr.get("switchgw")+"\n")   
            f.write("no shut"+"\n\n")
        if(configstr.get("licfilepath")!=None):
            f.write("install license bootflash:" +configstr.get("licfilepath")+"\n\n")
        if(configstr.get("telnetvar")!=None and configstr.get("telnetvar").lower()=="enable"):
            f.write("feature telnet"+"\n\n")
        if(configstr.get("telnetvar")!=None and configstr.get("telnetvar").lower()=="disable"):
            f.write("no feature telnet"+"\n\n")
        if(configstr.get("clockvar")!=None):
            if(configstr.get("clockvar").find("select format--")>0):
                f.write("clock format "+configstr.get("clockvar").lower()+"\n\n") 
            else:
                f.write("\n")              
        if(configstr.get("timez")!=None):
            if configstr.get("timez") != '':
                f.write("clock timezone "+configstr.get("timez")+" "+configstr.get("hrvar")+" "+configstr.get("minvar")+"\n\n")
        if(configstr.get("httpvar")!=None and configstr.get("httpvar").lower()=="enable"):
            f.write("feature http-server"+"\n\n")
        if(configstr.get("httpvar")!=None and configstr.get("httpvar").lower()=="disable"):
            f.write("no feature http-server"+"\n\n")
        f.close()

    def createNewTclFile(self,vernxos):
        self.logger.info("Going to update the Tcl script ")
        #filen = os.path.dirname(os.path.abspath(__file__))
        curdir = os.getcwd()
        #readfile = curdir+self.pathsep+"poap_script.tcl"
        readfile = self.curntdir+os.path.sep+"basefiles"+os.path.sep+"poap_script.tcl"
        writefile =curdir+self.pathsep+"toDir"+self.pathsep+"poap_script.tcl"
        self.logger.info("current path is "+readfile+"  "+curdir)
        f = open(readfile,"r")
        fw = open(writefile,"w+")
        contents = f.readlines()
        for line in contents:
            if "_image_version " in line:
                linesplit = re.split(r'\s+',line.strip())
                fw.write(linesplit[0]+" "+linesplit[1]+"    "+"\""+vernxos+"\""+"\n")
            else:
                fw.write(line)
        f.close()
        fw.close()

    def copyImagesFromDir(self,dirpath,platformval,vernxos):
        self.logger.info("Copying images from dirpath "+dirpath+" platformval"+platformval+" vernxos"+vernxos)
        #/home/osboxes/Documents/imagesdir
        curdir = os.getcwd()
        for filename in os.listdir(dirpath):
            if(filename.endswith(".bin")):
                 splits = filename.split("mz.")
                 startname = splits[0].split("-")[0]
                 versionstr = splits[1].split(".bin")[0]
                 print " startname",startname," versionstr ",versionstr
                 if((startname.lower() == platformval.lower()) and (vernxos == versionstr)):
                      print "name match and version"
                      srcdir = dirpath+self.pathsep + filename
                      destdir = curdir+self.pathsep+"toDir"+self.pathsep+filename
                      shutil.copy(srcdir,destdir)
                 print "startname>>",startname," versionstr>>",versionstr," splits >> ",splits," platcorm",platformval

    def clearDirectories(self):
        print "clearing the temp directo"
	
    def cbp(self):
        self.logger.info("platform selected variable is"+ str(self.platchk.get()))
        if self.platchk.get() == 1:
            self.platform.configure(state="disabled")
            self.platform1.configure(state="active")
        if self.platchk.get() == 0:
            self.platform.configure(state="active")
            self.platform1.configure(state="disabled")

    def cbnv(self):
        self.logger.info( "nxosver selected variable is"+ str(self.verchk.get()))
        if self.verchk.get() == 1:
            self.nxosver.configure(state="disabled")
            self.nxosver1.configure(state="active")
        if self.verchk.get() == 0:
            self.nxosver.configure(state="active")
            self.nxosver1.configure(state="disabled")
			
    def addIndexPage(self):
        im = Image.open("icons/poaptrans.png")
        resized = im.resize((110,60),Image.ANTIALIAS)
        img = ImageTk.PhotoImage(resized)
        ImageLabel1 = Label(self, image = img)#image = img
        ImageLabel1.image = img

        ImageLabel2= Label(self,text="CISCO MDS POAP Configuration Tool",foreground="gray",font=("Times",17))

        im2 = Image.open("icons/ciscowhitelogo.gif")
        resized2 = im2.resize((110,60),Image.ANTIALIAS)
        img2 = ImageTk.PhotoImage(resized2)
        ImageLabel3 = Label(self,image=img2)#image=img2
        ImageLabel3.image = img2

        self.loadlabphoto = PhotoImage(file="icons/load4020.gif")
        self.checklabphoto = PhotoImage(file="icons/check2.gif")
        
        platformlist = []
        curntdir = os.getcwd()
        currntfile = self.platconf        

        with open(currntfile) as fo:
            innercontents = fo.readlines()
            for line in innercontents:
               if(line.strip() != ""):
                 platformlist.append(line.replace('\n','').replace('\r',''))
        self.logger.info("platformlist contents read are ")
        self.logger.info(platformlist)    
        
        #platform
        self.varb = StringVar(self)
        self.varb.set("--Select--")
        self.platform = OptionMenu(self,self.varb,*platformlist)
        self.platform.config(width=14)  

        self.platchk = IntVar()
        self.platch = Checkbutton(self, variable=self.platchk,command=self.cbp)

        versionlist = []
        curfile = self.nxverconf        

        with open(curfile) as fo:
            innercontents = fo.readlines()
            for line in innercontents:
               if(line.strip() != ""):
                   versionlist.append(line.replace('\n',''))
        self.logger.info( "versionlist contents read are ")
        self.logger.info(versionlist)

        #nxos ver
        self.varv = StringVar(self)
        self.varv.set("--Select--")
        self.nxosver = OptionMenu(self,self.varv,*versionlist)
        self.nxosver.config(width=14)
		
        self.verchk = IntVar()
        self.nxverchk = Checkbutton(self, variable=self.verchk,command=self.cbnv)
		
        #telnet
        self.vart = StringVar(self)
        self.vart.set("--Select--")
        self.telnet = OptionMenu(self,self.vart,"--Select--","Enable","Disable")
        self.telnet.config(width=14)
        #clock
        self.varc = StringVar(self)
        self.varc.set("--Select Format--")
        self.clock = OptionMenu(self,self.varc,"--Select Format--","12-hours","24-hours")
        self.clock.config(width=14)

        #http
        self.varh = StringVar(self)
        self.varh.set("--Select--")
        self.httpval = OptionMenu(self,self.varh,"--Select--","Enable","Disable")
        self.httpval.config(width=14)

        #timezone hour and min        
        self.varhr = StringVar(self)
        self.varhr.set("Hr")
        self.timehr = Combobox(self,textvariable=self.varhr,values=["Hr","0","1","2","3","4","5","6","7","8","9","10","11","12"])
        self.timehr.config(width=3)
        self.varmin = StringVar(self)
        self.varmin.set("Min")
        self.timemin = Combobox(self,textvariable=self.varmin,values=["Min","0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"])
        self.timemin.config(width=3)
       

        topspace1 = Label(self,text="")
        topspace2 = Label(self,text="")
        topspace3 = Label(self,text="")
        topspace4 = Label(self,text="")
        topspace5 = Label(self,text="")
        emptylabel1side1 = Label(self,text="1")
        emptylabel1side2 = Label(self,text="2")
        emptylabel1side1rep = Label(self,text="1re")
        emptylabel1side2rep = Label(self,text="2re")
        emptylabel1side = Label(self,text="")
        emptylabel1 = Label(self,text="                  ")
        emptylabel2 = Label(self,text="                  ")
        emptylabel3 = Label(self,text="                  ")
        emptylabel4 = Label(self,text="                  ")
        emptylabel5 = Label(self,text="                  ")
        emptylabel6 = Label(self,text="                  ")
        emptylabel7 = Label(self,text="                  ")
        emptylabel8 = Label(self,text="                  ")
        emptylabel9 = Label(self,text="                  ")
        emptylabel10 = Label(self,text="                  ")
        emptylabel11 = Label(self,text="                  ")
        emptylabel12 = Label(self,text="                  ")
        emptylabel13 = Label(self,text="                  ")       
        emptylabel14 = Label(self,text="                  ")
        emptylabel15 = Label(self,text="                  ")
        emptylabel16 = Label(self,text="                  ")
        emptylabel17 = Label(self,text="                  ")       
        emptylabel18 = Label(self,text="                  ")
        emptylabel19= Label(self,text="                  ")
        emptylabel20 = Label(self,text="                  ")
        submitlabspace1 = Label(self,text="                  ")
        submitlabspace2 = Label(self,text="                  ")
        submitafterspace1 = Label(self,text="                  ")
        copyrightlabel = Label(self,text=" @Copyright 2017 ")
        self.loadinglabel = Label(self,text='',compound=RIGHT)
        label1 = Label(self,text="Platform : ")
        label2 = Label(self,text="NXOS Ver : ")
        label3 = Label(self,text="Serial Num : ")
        label15 = Label(self,text="                  ")
        label4 = Label(self,text="CONFIG : ")
        label5 = Label(self,text="Licence file name : ")
        label16 = Label(self,text="                   ")
        label6 = Label(self,text="Switch Name : ")
        label7 = Label(self,text="Password : ")
        label8 = Label(self,text="IP : ")
        label9 = Label(self,text="Mask : ")
        label10 = Label(self,text="GW : ")
        label17 = Label(self,text="                  ")           
        label11 = Label(self,text="Telnet : ")
        label18 = Label(self,text="                   ")
        label12 = Label(self,text="Clock : ")
        label19= Label(self,text="                  ")
        label13 = Label(self,text="Time Zone : ")       
        label20 = Label(self,text="                   ")
        label14 = Label(self,text="HTTP : ")
        
        #self.platform = Entry(self)
        #self.nxosver = Entry(self)
        self.platform1 = Entry(self)
        self.platform1.configure(state="disabled")
        self.nxosver1 = Entry(self)
        self.nxosver1.configure(state="disabled")
        self.serialnum = Entry(self)
        #self.imagedirpath = Entry(self)
        self.licensepath = Entry(self)
        self.switchname = Entry(self)
        self.password = Entry(self,show="*")
        self.switchip = Entry(self)
        self.mask = Entry(self)
        self.gateway = Entry(self)
        #self.telnet = Entry(self)
        #self.clock = Entry(self)
        self.timezone = Entry(self)
        #self.httpval = Entry(self)
        
        self.platform.grid(row=2,column=2,sticky=NSEW)
        self.platch.grid(row=2,column=3,sticky=E)
        self.platform1.grid(row=2,column=4,sticky=W)
        self.nxosver.grid(row=3,column=2,sticky=NSEW)
        self.nxverchk.grid(row=3,column=3,sticky=E)
        self.nxosver1.grid(row=3,column=4,sticky=W)
        self.serialnum.grid(row=4,column=2,sticky=NSEW)
        #self.imagedirpath.grid(row=7,column=2,sticky=E)
        self.licensepath.grid(row=7,column=2,sticky=NSEW)
        self.switchname.grid(row=9,column=2,sticky=NSEW)
        self.password.grid(row=10,column=2,sticky=NSEW)
        self.switchip.grid(row=11,column=2,sticky=NSEW)
        self.mask.grid(row=12,column=2,sticky=NSEW)
        self.gateway.grid(row=13,column=2,sticky=NSEW)
        self.telnet.grid(row=15,column=2,sticky=NSEW)
        self.clock.grid(row=17,column=2,sticky=NSEW)
        self.timezone.grid(row=19,column=2,sticky=NSEW)
        self.timehr.grid(row=19,column=3,sticky=E)
        self.timemin.grid(row=19,column=4,sticky=W)
        self.httpval.grid(row=21,column=2,sticky=NSEW)

        #emptylabel1side1rep.grid(row=19,column=3,sticky=E)
        #emptylabel1side2rep.grid(row=19,column=4,sticky=E)

        #emptylabel1side1.grid(row=1,column=3,sticky=E)
        #emptylabel1side2.grid(row=1,column=4,sticky=E)
        #emptylabel1side.grid(row=1,column=5,sticky=E)
        emptylabel1.grid(row=2,column=0,sticky=E)
        emptylabel2.grid(row=3,column=0,sticky=E)
        emptylabel3.grid(row=4,column=0,sticky=E)
        emptylabel4.grid(row=5,column=0,sticky=E)
        emptylabel5.grid(row=6,column=0,sticky=E)
        emptylabel6.grid(row=7,column=0,sticky=E)
        emptylabel7.grid(row=8,column=0,sticky=E)
        emptylabel8.grid(row=9,column=0,sticky=E)
        emptylabel9.grid(row=10,column=0,sticky=E)
        emptylabel10.grid(row=11,column=0,sticky=E)
        emptylabel11.grid(row=12,column=0,sticky=E)
        emptylabel12.grid(row=13,column=0,sticky=E)
        emptylabel13.grid(row=14,column=0,sticky=E)
        emptylabel14.grid(row=15,column=0,sticky=E)
        emptylabel15.grid(row=16,column=0,sticky=E)
        emptylabel16.grid(row=17,column=0,sticky=E)
        emptylabel17.grid(row=18,column=0,sticky=E)
        emptylabel18.grid(row=19,column=0,sticky=E)
        emptylabel19.grid(row=20,column=0,sticky=E)
        emptylabel20.grid(row=21,column=0,sticky=E)
        label1.grid(row=2,column=1,sticky=E)
        label2.grid(row=3,column=1,sticky=E)
        label3.grid(row=4,column=1,sticky=E)
        label15.grid(row=5,column=1,sticky=E)
        label4.grid(row=6,column=1,sticky=E)
        label5.grid(row=7,column=1,sticky=E)
        label16.grid(row=8,column=1,sticky=E)
        label6.grid(row=9,column=1,sticky=E)
        label7.grid(row=10,column=1,sticky=E)
        label8.grid(row=11,column=1,sticky=E)
        label9.grid(row=12,column=1,sticky=E)
        label10.grid(row=13,column=1,sticky=E)
        label17.grid(row=14,column=1,sticky=E)
        label11.grid(row=15,column=1,sticky=E)
        label18.grid(row=16,column=1,sticky=E)
        label12.grid(row=17,column=1,sticky=E)
        label19.grid(row=18,column=1,sticky=E)
        label13.grid(row=19,column=1,sticky=E)
        label20.grid(row=20,column=1,sticky=E) 
        label14.grid(row=21,column=1,sticky=E)
        submitlabspace1.grid(row=22,column=1,sticky=E)
        submitlabspace2.grid(row=23,column=1,sticky=E)
        topspace1.grid(row=1,column=0,sticky=E)
        topspace2.grid(row=1,column=1,sticky=E)
        topspace3.grid(row=1,column=2,sticky=E)
        topspace4.grid(row=1,column=3,sticky=E)
        topspace5.grid(row=1,column=4,sticky=E)

        ImageLabel1.grid(row=0,column=0,sticky=NSEW)
        ImageLabel2.grid(row=0,columnspan=4,column=1,padx=60,sticky=NSEW)
        #ImageLabel3.grid(row=0,column=4,sticky=E)

        #adding submit button
        submitbut = Button(self,text="Submit",command=lambda: self.call_on_thread())
        submitbut.grid(row=24,column=2,sticky=NSEW)
        submitafterspace1.grid(row=25,column=1,sticky=E)
        self.loadinglabel.grid(row=26,column=2,sticky=NSEW)
        copyrightlabel.grid(row=28,column=2,sticky=NSEW)

    def call_on_thread(self):
        self.loadinglabel.config(text= 'Please wait for processing..!',compound=RIGHT,image=self.loadlabphoto)
        t = threading.Thread(target=self.process_details)
        t.start()



 

if __name__ == "__main__":
    app =  PoapHome()
    app.title("CISCO MDS POAP Configuration Tool")
    app.mainloop()  



