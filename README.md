# cmda
Commandes utile pour les staff sur fivem !

# Il comporte :

+ /mpid --> envoyer un message privé à un joueur
+ /revive --> réanimer un joueur
+ /time --> chnager l'heure du jeu
+ /weather --> chnager la météo
+ /rpid --> pour connaitre le nom rp du joueur
------------ Systéme de warn ------------------
  + /warn --> avertis un joueur
  + /lwarn --> liste de warn du joueur (interface)
  + /cwarn --> clear les warn du joeur
----------------------------------------------

# Installation : 

1 - dezipper le fichier
2 - les mettres dans votre dossier choisi par exemple [admin]
3 - mettre ses lignes de commande suivante dans votre fichier server.cfg

add_ace group.admin utils.revive allow
add_ace group.admin utils.mpid allow
add_ace group.admin utils.time allow
add_ace group.admin utils.weather allow
add_ace group.admin utils.rpid allow
add_ace group.admin utils.warn allow
add_ace group.admin utils.lwarn allow
add_ace group.admin utils.cwarn allow

4 - et aussi toujours dans le fichier server.cfg mettez :
ensure cmda
   OU
ensure [nom_du_fichier]
par exemple :
ensure [admin]

# Utilisation des commandes :

/mpid [id] [message]
/revive [id]
/time [heure] [minute]
/weather [type*]      *clear / rain / extrasunny 
/rpid [id]
/warn [id] [raison]
/lwarn [id]
/cwarn [id]

# Pour des ajouts suplémentaire , vas sur mon serveur !

--> https://discord.gg/d7d7J64qB9
