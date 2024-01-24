# Question 1:
Toutes mes machines utilisent systemd pour les logs. Toutes les grandes distributions ont l'air d'utiliser systemd par défaut, et non pas rsyslog.
Pour affirmer que mes machines utilisent systemd, j'ai vérifié que le service rsyslog n'était pas lancé, et que le service systemd-journald était lancé.

```
# systemctl status rsyslog
Unit rsyslog.service could not be found.
```
```
# systemctl status systemd-journald
● systemd-journald.service - Journal Service
     Loaded: loaded (/usr/lib/systemd/system/systemd-journald.service; static)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
             /etc/systemd/system/systemd-journald.service.d
             └─override.conf
     Active: active (running) since Mon 2024-01-22 08:21:18 CET; 30min ago
TriggeredBy: ● systemd-journald-dev-log.socket
             ● systemd-journald.socket
       Docs: man:systemd-journald.service(8)
             man:journald.conf(5)
   Main PID: 120 (systemd-journal)
     Status: "Processing requests..."
      Tasks: 1 (limit: 52871)
   FD Store: 7 (limit: 4224)
     Memory: 10.0M
        CPU: 83ms
     CGroup: /system.slice/systemd-journald.service
             └─120 /usr/lib/systemd/systemd-journald
```

# Question 2: Analyse du fichier de configuration rsyslog

## Règles de Logging

### Logs du Kernel
- **Commenté** : `#kern.* /dev/console` : Les messages du kernel ne sont pas redirigés vers la console.

### Multiplexage des Logs
- **Logs Généraux** : `*.info;mail.none;authpriv.none;cron.none /var/log/messages`
  - Tout ce qui est niveau info ou plus élevé, sauf les mails, authentification privée, et cron sont redirigés vers `/var/log/messages`.
- **Authentification Privée** : `authpriv.* /var/log/secure`
  - Tous les messages d'authentification privée sont redirigés vers `/var/log/secure`.
- **Logs de Mail** : `mail.* -/var/log/maillog`
  - Tous les messages mail sont redirigés vers `/var/log/maillog`.
- **Logs de Cron** : `cron.* /var/log/cron`
  - Tous les messages de cron sont redirigés vers `/var/log/cron`.
- **Messages d'Urgence** : `*.emerg :omusrmsg:*`
  - Tous les messages d'urgence sont envoyés à tous les utilisateurs.
- **Erreurs Critiques de News et UUCP** : `uucp,news.crit /var/log/spooler`
  - Erreurs critiques pour uucp et news sont redirigées vers `/var/log/spooler`.
- **Logs de Démarrage** : `local7.* /var/log/boot.log`
  - Tous les messages de démarrage sont redirigés vers `/var/log/boot.log`.

## Commentaires
- **Règles de forwarding (commentées)** : Exemple de configuration pour le forwarding de logs à un hôte distant via TCP.

## Conclusion
Le fichier de configuration rsyslog actuel définit plusieurs règles pour diriger les messages de log vers différents fichiers en fonction de leur type et de leur niveau de gravité. Cependant, plusieurs options, comme le logging du kernel et le forwarding de logs, sont actuellement commentées et donc désactivées.

# Question 3: Pourquoi écrire dans les fichiers est une erreurs pour les logs systèmes ?

L'écriture des logs par `rsyslog` ou `systemd` (via `journald`) dans des fichiers présentent des inconvénients, même si cette pratique est courante et souvent bien gérée par ces outils:

1. **Risques de Perte de Données en Cas de Panne Système** :
   - L'écriture dans des fichiers peut entraîner une perte de données en cas de panne du système ou d'arrêt inattendu, surtout si les logs ne sont pas correctement flushés sur le disque. Les systèmes comme `journald` minimisent ce risque en utilisant des méthodes d'écriture plus robustes. Cependant, il devient compliquer de comprendre ce qui s'est passé en cas de panne du système, puisque les logs sont stockés sur la machine qui est en panne.

2. **Gestion de la Rotation et de l'Archivage** :
   - La gestion de la rotation et de l'archivage des fichiers de log peut devenir complexe, surtout dans les systèmes avec de grands volumes de logs. Bien que des outils comme `logrotate` puissent aider, cela ajoute une couche supplémentaire de gestion. Il est préférable de gérer la rotation et l'archivage des logs au niveau du serveur de gestion de logs, afin de centraliser la gestion et de réduire la complexité.

3. **Sécurité et Intégrité des Logs** :
   - Les fichiers de log peuvent être modifiés, supprimés ou altérés. Dans des environnements où la sécurité et l'audit des logs sont critiques, cela peut poser un problème. Des formats de stockage plus sécurisés ou des mécanismes de vérification d'intégrité peuvent être préférables. Les systèmes de centralisations de logs permettent d'envoyer les logs à un serveur dédié, qui permet seulement la concaténation des logs, et non leur modification.

4. **Scalabilité et Centralisation** :
   - Dans les architectures distribuées ou à grande échelle, la centralisation des logs dans un système de gestion de logs dédié (comme avec une stack ELK) peut offrir une meilleure scalabilité et des capacités d'analyse plus avancées que les fichiers locaux.

# Question 4 : Peut on logger depuis la cli ? Comment ? Tester logger

Oui, il est tout à fait possible de générer des logs depuis la ligne de commande (CLI) en utilisant la commande `logger`. `logger` est un outil simple sous UNIX et Linux qui permet d'envoyer des messages personnalisés au système de journalisation.

Utilisation de `logger` :

1. **Envoyer un Message Simple** :
   - Pour envoyer un message simple au journal système, tapez :
     ```bash
     logger "Mon message de test"
     ```
   - Ce message sera traité par le système de journalisation comme n'importe quel autre message syslog.

2. **Spécifier la Priorité** :
   - Vous pouvez spécifier la priorité (facility.level) du message. Par exemple, pour envoyer un message avec une priorité d'alerte :
     ```bash
     logger -p local0.alert "Alerte de test"
     ```
   - Les facilities courantes incluent `user`, `local0` à `local7`, `mail`, `daemon`, etc. Les levels incluent `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`.

3. **Ajouter un Tag au Message** :
   - Vous pouvez ajouter un tag pour faciliter l'identification du message dans les logs :
     ```bash
     logger -t MONAPPLICATION "Message de test"
     ```
4. **Vérifier les Logs** :
   - Après avoir utilisé `logger`, on peut les logs pour voir si le message est apparu. Ma configuration de rsyslog fait que les messages kernel sont écrits dans `/var/log/kern.log`.
     ```bash
      # logger -p kern.info "Info de logger!"
      # tail -n 1 /var/log/kern.log
      [ 3181.910473] My test kernel message
     ```


# Question 5 / 6 / 7: Syslog en réseau

Pour configurer `rsyslog` afin de recevoir les logs d'autres machines sur le réseau, il faut activer et configurer les fonctionnalités de réception de logs en réseau de `rsyslog`:

1. **Installer Rsyslog** :
   - On installe rsyslog sur les deux machines :
     ```bash
     sudo apt install rsyslog
     ```
     pour une debian, ou
     ```bash
      sudo dnf install rsyslog
      ```
      pour une fedora.

2. **Modifier la Configuration de Rsyslog** :
   - On edite le fichier de configuration de `rsyslog`, généralement situé à `/etc/rsyslog.conf`, et on decommente ou ajoute les lignes suivantes pour activer l'écoute sur les ports réseau :
     ```
     module(load="imudp") # pour UDP
     input(type="imudp" port="514")

     module(load="imtcp") # pour TCP
     input(type="imtcp" port="514")
     ```
   - Ces lignes chargent les modules `imudp` et `imtcp` pour écouter respectivement les ports UDP et TCP 514, qui sont les ports standards pour syslog.

3. **Configurer les règles de Firewall** :
   - On ouvre les port pour que le parefeu  autorise le trafic entrant sur le port 514.
   - Pour `iptables`, une règle ressemblerait à :
     ```bash
     iptables -A INPUT -p udp --dport 514 -j ACCEPT
     iptables -A INPUT -p tcp --dport 514 -j ACCEPT
     ```
   - Ou pour `firewalld`:
     ```bash
     firewall-cmd --permanent --add-port=514/tcp
     firewall-cmd --permanent --add-port=514/udp
     firewall-cmd --reload
     ```

4. **Redémarrer Rsyslog** :
   - Après avoir modifié la configuration, on redemarre `rsyslog` pour appliquer les changements :
     ```bash
     sudo systemctl restart rsyslog
     ```

5. **Configurer les Clients** :
   - Sur les machines clientes, on configure `rsyslog` pour envoyer leurs logs vers votre serveur `rsyslog`. Dans leur fichier `/etc/rsyslog.conf` on ajoute :
     ```
      action(type="omfwd"
        queue.filename="fwdRule1"       # unique name prefix for spool files
        queue.maxdiskspace="1g"         # 1gb space limit (use as much as possible)
        queue.saveonshutdown="on"       # save messages to disk on shutdown
        queue.type="LinkedList"         # run asynchronously
        action.resumeRetryCount="-1"    # infinite retries if host is down
        Target="arm.orb.local" Port="514" Protocol="tcp")
     ```
     Pour plus d'informations sur les options de configurations: https://www.rsyslog.com/doc/configuration/modules/omfwd.html
   
6. **Tester la Configuration** :
  On essaie d'envoyer un message de test depuis une machine cliente :
  ```bash
  logger "Test du syslog en réseau"
  ```

  Avec ma configuration, les messages sont écrits dans `/var/log/messages` sur le serveur `rsyslog`. Lorsque j'envoie un message depuis une machine cliente, j'obtiens :
  ```
  # tail -n 1 /var/log/messages
  Jan 22 09:49:20 intel root[825]: Test du syslog en réseau
  ```

# Question 8 / 9: Configuration de logrotate
La configuration de `logrotate` s'effectue en créant ou en modifiant des fichiers de configuration dans le répertoire `/etc/logrotate.d/`. Chaque fichier de configuration dans ce répertoire définit les règles de rotation pour un ensemble spécifique de fichiers de log. Voici les étapes pour configurer `logrotate` :

1. **Créer ou Modifier un Fichier de Configuration** :
   - On crée un nouveau fichier de configuration dans `/etc/logrotate.d/` pour le service ou l'application dont on veut gérer les logs. Par exemple, pour Apache, on pourrait créer un fichier nommé `apache2`.
   - On ouvre ce fichier avec un éditeur de texte, par exemple :
     ```bash
     sudo nano /etc/logrotate.d/apache2
     ```

2. **Définir les Chemins des Logs** :
   - Au début du fichier, on indique les chemins vers les fichiers de log à gérer. Par exemple :
     ```
     /var/log/apache2/*.log {
     ```
   - Cette ligne indique que `logrotate` doit gérer tous les fichiers se terminant par `.log` dans `/var/log/apache2/`.

3. **Spécifier les Options de Rotation** :
   - On définit ensuite les options de rotation. Par exemple :
     ```
     daily
     rotate 7
     compress
     missingok
     notifempty
     create 640 root adm
     postrotate
         /etc/init.d/apache2 reload > /dev/null
     endscript
     }
     ```
   - Ici, `daily` signifie que les logs sont tournés chaque jour, `rotate 7` garde 7 rotations avant de les supprimer, `compress` compresse les fichiers rotatifs, `missingok` ne génère pas d'erreur si un fichier de log est absent, et `notifempty` ne tourne pas les fichiers vides. La section `postrotate` définit des commandes à exécuter après la rotation des logs.

4. **Tester la Configuration** :
   - Pour tester la configuration, on exécute `logrotate` avec l'option `--debug` :
     ```bash
     sudo logrotate --debug /etc/logrotate.d/apache2
     ```
   - Cela affiche ce que `logrotate` ferait sans exécuter les rotations, ce qui permet de vérifier la configuration.

5. **Automatiser `logrotate` avec Cron** :
   - `logrotate` est généralement exécuté automatiquement une fois par jour via `cron`. Le script de `cron` pour `logrotate` se trouve habituellement dans `/etc/cron.daily/`.

En suivant ces étapes, on configure `logrotate` pour gérer la rotation et la gestion des fichiers de log, ce qui est essentiel pour éviter que les fichiers de log ne consomment trop d'espace disque et pour maintenir une gestion efficace des logs sur un système.

# Question 10 / 11: combien de temps sont conservés les logs d'authentification ? Au vu RGPD, que devrait-on faire ?

## Durée de Conservation des Logs d'Authentification
On regarde le fichier de configuration pour connaitre les valeurs par defaut de logrotate:
```
cat /etc/logrotate.conf
# see "man logrotate" for details

# global options do not affect preceding include directives

# rotate log files weekly
weekly

# keep 4 weeks worth of backlogs
rotate 4

# create new (empty) log files after rotating old ones
create

# use date as a suffix of the rotated file
dateext

# uncomment this if you want your log files compressed
#compress

# packages drop log rotation information into this directory
include /etc/logrotate.d

# system-specific logs may also be configured here.
```

On voit que, par défaut, les logs sont conservés pendant 4 semaines.

## RGPD

# Question 12 / 13 / 14 / 15: Analyser un service lancé par systemd

On installe nginx sur une machine :

```bash
sudo dnf install nginx-all-modules
```

Puis on lance le service nginx :
```bash
sudo systemctl start nginx
```

On regarde le status du service nginx :
```bash
sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: active (running) since Mon 2024-01-22 10:52:45 CET; 2min 33s ago
    Process: 2174 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 2176 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 2178 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 2179 (nginx)
      Tasks: 17 (limit: 52871)
     Memory: 17.1M
        CPU: 69ms
     CGroup: /system.slice/nginx.service
             ├─2179 "nginx: master process /usr/sbin/nginx"
             ├─2180 "nginx: worker process"
             ├─2181 "nginx: worker process"
             ├─2182 "nginx: worker process"
             ├─2183 "nginx: worker process"
             ├─2184 "nginx: worker process"
             ├─2186 "nginx: worker process"
             ├─2187 "nginx: worker process"
             ├─2189 "nginx: worker process"
             ├─2190 "nginx: worker process"
             ├─2191 "nginx: worker process"
             ├─2192 "nginx: worker process"
             ├─2193 "nginx: worker process"
             ├─2194 "nginx: worker process"
             ├─2195 "nginx: worker process"
             ├─2196 "nginx: worker process"
             └─2197 "nginx: worker process"

Jan 22 10:52:45 arm systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 22 10:52:45 arm nginx[2176]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 22 10:52:45 arm nginx[2176]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 22 10:52:45 arm systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```

On peut voire que le service est bien lancé. De plus, on peut voir les dernières logs du service. Pour voire l'entièreté des logs, on peut utiliser la commande `journalctl` :

```bash
sudo journalctl -u nginx
Jan 22 10:52:21 arm systemd[1]: nginx.service: Unit cannot be reloaded because it is inactive.
Jan 22 10:52:45 arm systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 22 10:52:45 arm nginx[2176]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 22 10:52:45 arm nginx[2176]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 22 10:52:45 arm systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```

Ces logs sont stockés par le service de logs de systemd. Ces logs sont stockés dans `/var/log/journal/`. Elles sont stockées dans un format binaire, et peuvent être lues avec la commande `journalctl`.

# Question 16: Analyser le comportement sur une Debian standard
Sur une machine Debian 11 fraichement installée, on installe rsyslog :
```bash
sudo apt install rsyslog
```

On démarre le service rsyslog :
```bash
sudo systemctl start rsyslog
```

On essaie d'envoyer un message de test avec `logger` :
```bash
logger "testing"
```

On regarde les logs de rsyslog. Dans la configuration de base de rsyslog, les messages se trouvent dans le ficher `/var/log/syslog`. On peut les afficher avec la commande `cat` :
```bash
sudo cat /var/log/messages | tail -n 1
Jan 22 11:03:36 debian root: testing
```

On peut voir que le message a bien été reçu par rsyslog.
Faisons de même avec systemd-journald :

```bash
sudo journalctl | tail -n 1
Jan 22 11:03:36 debian root[5087]: testing
```

On peut voir que le message a également été reçu par systemd-journald.

# Question 17: En quoi Docker ressemble à systemd pour la gestion des logs ?
Docker et systemd sont tous les deux des systemd gère tous les deux (dans l'idée, bien que la réalité soit plus compliquée que ça) le cycles de vies des processus, et permettent de les lancer, les arrêter, et de les surveiller. De plus, ils permettent tous les deux de gérer les logs des processus. Les deux permettent de collecter et d'afficher les logs des processus d'une manière centralisés. Avec systemd, on a journalctl. Avec docker, on a docker logs.

# Question 18: Peut-on quand même utiliser rsyslog pour les logs de docker en jouant sur la configuration du conteneur ?

Oui, il est possible d'utiliser rsyslog pour les logs de docker. Pour cela, il faut modifier la configuration du conteneur docker pour qu'il utilise le driver `syslog`. Par exemple, pour un conteneur nginx, on peut utiliser la commande suivante pour lancer le conteneur :
```bash
docker run --log-driver=syslog -d nginx
```

Si le serveur rsyslog est distant ou si on souhaite configurer des options spécifiques, on peut utiliser l'option --log-opt. Par exemple :
```bash
docker run --log-driver=syslog --log-opt syslog-address=udp://arm.orb.local:514 ...
```

Ici, `arm.orb.local` est l'adresse IP du serveur rsyslog et 514 est le port standard pour syslog.

Je ne pense pas que cela soit une bonne pratique, pour plusieurs raisons :
- Docker centralise déjà les logs des conteneurs, et permet de les afficher avec la commande `docker logs`. Il est donc inutile de les centraliser à nouveau avec rsyslog.
- Je dirai qu'il est même contre-productif de centraliser les logs des conteneurs avec rsyslog, puisque l'on veut généralament séparer les logs de la machine hôte et des conteneurs. En centralisant les logs des conteneurs avec rsyslog, on perd cette séparation.

Selon les cas d'utilisation, il peut être intéressant d'envoyer les logs des conteneurs vers un serveur de logs dédié, comme un ELK. Cependant, lorsqu'on a des conteneurs distribués sur plusieurs machines, on met très souvent une couche d'orchestration en plus telle que Kubernetes, avec des outils de monitoring et de gestion des logs dédiés. Dans ce cas, il est inutile d'utiliser rsyslog pour centraliser les logs des conteneurs.

Les logs des conteneurs sont généralement stockés dans `/var/lib/docker/containers/`. On peut les afficher avec la commande `cat` :
```bash
sudo cat /var/lib/docker/containers/CONTAINER_ID/CONTAINER_ID-json.log
```

# Question 19: Que fait `docker inspect <ID> | grep Log` ?
```bash
docker inspect 151726aabd45 | grep Log
        "LogPath": "",
            "LogConfig": {
               "Type": "syslog",
                "Config": {}
            },
```

Cette commande affiche la configuration de logging du conteneur. Ici, on peut voir que le driver de logging est `syslog`.


# Jour 2 - Déploiement d'une solution de centralisation de logs

## Rappel des objectifs

Voici le cahier de charges initial :
* 1) Tout d'abord collecter des logs et les agréger en un point unique :
    * - logs systèmes d'une machine (fruits de rsyslog)
    * - logs de systemd (attention aux doublons si systemd forwarde vers syslog, car vous n'avez pas le droit de modifier ça sur la machine supervisée
    * - logs autres (ceux dont le fichier est directement géré par l'application qui loggue : ex apache)
    * - logs d'un conteneur docker (pour ça, ciblez un conteneur particulier, apache ou nginx, et pas un de ceux qui constitue la stack
    * - logs depuis UDP514 (mode syslog distant) que vous testerez avec logger (car je n'ai pas de hardware switch ou routeur à vous mettre à dispo)
    * 

* 2) Visualiser ces logs, via grafana, par exemple. Deux tableaux à minima dans le dashboard :
    * - tous flux agrégés, au fil de l'eau (je sais, c'est sale et ça va être hyper verbeux... ) à la façon d'un "tail -f"
    * - les flux agrégés d'un service :
        * - si nginx natif, logs de systemd qui le lance ET des "acces" ou "error"
    * 

* 3) gérer un "log rotate" :
    * - soit grâce à un mécanisme sur le backend de stockage des logs
    * - soit par une fonctionnalité du collecteur lui-même
    * 

* 4) Alerter :
    * - envoyer un mail ou un sms
    * - sur une analyse de loggg
    * 

Ce compte rendu répond aux points 1 et 2.

## Choix de la stack

La stack choisi est la suivante:

* Loki pour la collecte des logs
* Grafana pour la visualisation des logs
* Le tout dans un cluster Kubernetes

Côté client, on utilisera promtail dans un conteneur pour collecter les logs.

## Installation du cluster

### Playbook Ansible

Afin d'automatiser la création du cluster kubernetes, nous utiliserons un playbook ansible. Vous retrouverez ce playbook dans le dossier `ansible` dans le repo git.
Ce playbook va:
- Install Docker
- Mettre en place un NFS entre les noeuds. Ceci est nécessaire pour que les noeuds puissent partager les volumes persistants.
- Préparer le manifest RKE (Rancher Kubernetes Engine)
- Installer RKE

Afin de lancer ce playbook, il faut:
- Avoir Ansible d'installé
- Avoir un accès SSH aux noeuds
- Avoir un utilisateur avec les droits sudo sur les noeuds
- Avoir la CLI RKE d'installé
- Avoir la CLI kubectl d'installé

Pour lancer le playbook, il faut:
- Modifier le fichier `inventory.ini` pour y mettre les adresses IP des noeuds, et préciser le nom d'utilisateur et le chemin vers la clé SSH. Indiquer la localisation du noeud est optionnel.

Une fois les prérequis remplis, il suffit de se placer dans le dossier `ansible` et de lancer la commande `ansible-playbook playbook.yaml`

### Terraform
Une fois le playbook Ansible terminé, votre cluster est prêt. Cependant, il n'y encore rien de déployé dessus. Pour cela, nous allons utiliser Terraform. Terraform sera utilisé afin de définir:
- Une `storage class` pour les volumes persistants en NFS
- Le déploiement de Loki
- Le déploiement de Grafana
- Le déploiement d'un Prometheus
- La configuration de Grafana pour qu'il puisse récupérer les logs de Loki
- La configuration des ingress pour Grafana et Loki

Prérerequis:
- Avoir Terraform d'installé
- Avoir un nom de domaine qui point vers un de vos control plane. Vous pouvez utiliser `sslip.io` si vous n'avez pas de nom de domaine disponible.

Il est conseillé de bouger le fichier `kube_config_cluster.yml` situé du le dossier `ansible`. Cela facilitera le lancement des commandes Terraform, et plus tard, kubectl, puisque c'est la localisation par défaut des fichiers de configurations de cluster Kubernetes.

Pour lancer Terraform, il faut:
- Se placer dans le dossier `terraform`
- Modifier les fichiers `resources/grafana-ingress.yaml` et `resources/loki-ingress.yaml` pour y mettre votre nom de domaine.
- Lancer la commande `terraform init`
- Lancer la commande `terraform apply`. A cette étape, Terraform va vous demander l'IP du serveur NFS. Il s'agit du premier host du groupe `server` définit dans le fichier `inventory.ini` du playbook Ansible.

Une fois Terraform terminé, vous devriez voir votre Grafana accessible sur votre nom de domaine. Pour push des logs, il suffira d'utiliser la route `/loki/api/v1/push` de votre nom de domaine (ceci est la route par défaut).
A moins que vous ayez changer les variables de Terraform, les credentials par défaut sont `admin` et `admin` pour Grafana.

Grafana est entièrement configuré pour récupérer les logs de Loki. Cependant, il n'y a pas encore de Dashboard de créé. 

## Configuration d'un client

J'ai choisi d'utiliser Promtail pour collecter les logs. Promtail est un agent qui va collecter les logs et les envoyer à Loki. Promtail est fourni par Grafana, et est disponible sous forme de conteneur Docker. C'est sous cette forme que nous allons le déployer dans une machine cliente.
Le but est:
- De rediriger les logs de systemd
- De rediriger les logs de Docker
- D'écouter sur le port 514 afin de récupérer des logs venant d'un syslog (local ou distant)

Pour se faire, nous allons créer un fichier de configuration pour Promtail, ainsi qu'un docker-compose pour le déployer.

### Configuration de Promtail

Voici un exemple de fichier de configuration pour Promtail:
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://michel.simonlucido.com/loki/api/v1/push

# Listen on port 514 for syslog messages.
listen_syslog:
  - job_name: syslog
    syslog:
      listen_address: 0.0.0.0:514
      labels:
        job: "syslog"

    # Parse log line in common syslog format and rewrite hosts
    relabel_configs:
      - source_labels: ['__syslog_message_hostname']
        target_label: 'host'

  # Parse docker logs
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
    pipeline_stages:
      - static_labels:
          job: "docker"

  # Parse all files in `/var/log` that ends with log
  - job_name: log_files
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  # Parse journald logs.
  - job_name: journald
    journal:
      json: false
      max_age: 12h
      path: /var/log/journal
      labels:
        job: systemd-journal
    # Rewrite some common labels
    relabel_configs:
      - source_labels: ["__journal__systemd_unit"]
        target_label: "unit"
      - source_labels: ["__journal__hostname"]
        target_label: host
      - source_labels: ["__journal_priority_keyword"]
        target_label: level
      - source_labels: ["__journal_syslog_identifier"]
        target_label: syslog_identifier
    # Don't send promtail log to Loki
    pipeline_stages:
      - match:
          selector:  '{unit="promtail.service"}'
          action: drop
```

Ce fichier de configuration est assez simple. Il va:
- Ecouter sur le port 514 pour récupérer des logs syslog
- Ecouter sur le socket Docker pour récupérer les logs des conteneurs
- Ecouter sur le dossier `/var/log` pour récupérer les logs des applications
- Ecouter sur le journal systemd pour récupérer les logs de systemd

N'oubliez pas de changer l'URL de Loki pour qu'elle pointe vers votre Loki.

Je pars du postulat que ce fichier de configuration sera situé dans `./promtail/config.yml`.

### Docker-compose

Voici un exemple de docker-compose pour déployer Promtail:

```yaml
version: "3"

services:
  promtail:
    image: grafana/promtail:2.9.0
    volumes:
      - /var/log:/var/log
      - ./promtail:/etc/promtail/
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/config.yml
    ports:
      - "514:514"
```

Ce docker-compose est très simple. En plus de déployer le conteneur Promtail, il va:
- Monter le dossier `/var/log` du host dans le conteneur. Cela permettra à Promtail de récupérer les logs des applications, ainsi que les logs de systemd.
- Monter le fichier de configuration de Promtail dans le conteneur
- Monter le socket Docker dans le conteneur. Cela permettra à Promtail de récupérer les logs des conteneurs.
- Exposer le port 514 du conteneur. Cela permettra à Promtail de récupérer des logs syslog.

Une fois ce docker-compose créé, il suffit de le lancer avec la commande `docker-compose up -d`.

## Visualisation des logs

Maintenant que nous avons un client qui envoie des logs à Loki, nous allons pouvoir les visualiser dans Grafana.

### Création d'un Dashboard

Afin de visualiser les logs, nous allons créer un Dashboard Grafana. Afin de rendre la tâche moins pénible, vous retrouverez un fichier de Dashboard à la racine du repo git. Ce fichier est au format JSON, et peut être importé dans Grafana de la manière suivante:

- Se connecter à Grafana
- Ouvrir le menu en haut à droite 
- Cliquer `Dashboard`
- Cliquer sur `New`
- Cliquer sur `Import`
- Cliquer sur `Upload dashboard JSON file`
- Selectionner le fichier `loki-dashboard.json` du repo git
- Dans le menu déroulant `Loki datasource`, selectionner `Loki`
- Cliquer sur `Import`

Vous devriez maintenant avoir un Dashboard avec deux tableaux:
- Un tableau avec tous les logs
- Un tableau avec les logs venant d'un conteneur nommé `nginx` (peut importe sa provenance)

Libre à vous de modifier ce Dashboard pour qu'il corresponde à vos besoins.