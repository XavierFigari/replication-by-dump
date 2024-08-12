# Dump and Restore

## Création des Docker containers

Utilisation d'un docker-compose pour créer les containers nécessaires à la réalisation de l'exercice.
- sql-01 : serveur MariaDB (Master)
- sql-svg : serveur MariaDB (Slave)

Voir [docker-compose.yml](docker-compose.yml)

## Lancement des containers

`docker-compose up -d`

## Cron job to dump the database in sql-01, and to restore it in sql-svg

Editer un fichier /etc/cron.d/dump_db en sudo :
`sudo vim /etc/cron.d/dump_db`
```shell
# Dump the database every 5 minutes
*/1 * * * * xavier /usr/bin/docker exec sql-01 bash -x /dump.sh
*/1 * * * * xavier /usr/bin/docker exec sql-svg bash -x /restore.sh
```

Voir les fichiers dump.sh et restore.sh pour voir les commandes exécutées.

# Définitions

### Replication

> **Replication :** in SQL databases is the process of copying data from the source database to another one (or multiple ones) and vice versa. 

Data from one database server are constantly copied to one or more servers.

You can use replication to :

*   distribute and balance requests across a pool of replicated servers, 
*   provide failover and high availability of MariaDB databases. 

Two types of database replication : 

*   **Master-Master = Primary / Primary**
*   **Master-Slave = Primary / Replica**

### Failover

> **Failover** is the process of switching to a designated backup recovery facility. 

A failover happens when the primary site fails due to an unexpected disaster or in case of planned maintenance.

The recovery facility is usually a recovery site that contains a replicated copy of all the systems and data from your primary production site. Any changes made during a failover are saved to [virtual storage](https://phoenixnap.com/glossary/storage-virtualization).

_For a failover to work, there must be a backup_ [_bare metal server or virtual machine_](https://phoenixnap.com/blog/bare-metal-vs-vm) _that acts as the recovery site system, ready to replace the primary site in case of failure. Since failover is an essential step in disaster recovery, the backup systems themselves must be immune to failure._

_Failover and disaster recovery in whole is required for systems that require constant availability. At the server level, the backup environment tracks the "pulse" of the primary server and performs an automated failover if it detects an outage._

### Failback

> **Failback** is a business continuity mechanism used when the primary production site is up and running again. Production is returned to its original (or new) site during a failback, and any changes saved in the virtual storage are synchronized.

### How a Failover Works?

There are two ways to set up a failover system :  

*   **active-active** configuration
    *   multiple nodes are running simultaneously. 
    *   This allows them to share the workload and prevent any one node from overloading. 
    *   If one node stops working, its workload is taken up by other active nodes until it reactivates.
*   **active-passive** (or active-standby) configuration. 
    *   also includes multiple nodes, but not all of them are active at the same time. 
    *   Once an active node stops working, a passive node is activated and acts as a failover node. 
    *   When the primary node is functioning again, the backup node switches operations back to the primary node and becomes passive again.

Both setups require at least two nodes (servers or VMs) to work properly.

Regardless of the failover method, both configurations require that each node has an identical configuration. This ensures consistency and stability when switching between sites

### How a Failback Works?

**Failback** is the process of switching back to the primary site after the planned or unplanned disruption has been resolved. Failback usually follows failover as a part of a [disaster recovery plan](https://phoenixnap.com/blog/disaster-recovery-plan-checklist).

Failback is not the only way to finalize a failover. When working with virtual machines, you can perform a permanent failback, making the backup virtual machine the new primary site.

During a failover state, admins interact with a backup site. Any changes made in that period are saved as _change data_.

Once a failback happens, synchronizing the primary and recovery sites involves copying _change data_ from the recovery to the primary site. This prevents the need for a complete system copy, saving time and improving reliability.

Successfully performing a failback requires some preparation. Consider the following steps before switching back to the primary site:

*   Check the quality and network bandwidth of the connection to the primary site.
*   Check all data at the backup site for potential errors. This is especially important for critical files and documentation.
*   Thoroughly test all primary systems before starting a failback.
*   Prepare and implement a failback plan that minimizes downtime and user inconvenience.

Source : [https://phoenixnap.com/kb/failover-vs-failback](https://phoenixnap.com/kb/failover-vs-failback) 

### Primary - replica (Master - Slave)

> In this setup, the data stored in the master will be live-copied to the slave. Only the master performs write transactions.

Master-slave replication is a type of replication in which data is replicated one-way only. 

A server replicating data from another server is called a slave, while the other server is called the master. Data changes happen on the master server, while the slave server automatically replicates the changes from the master server. You can change the data on the slave server, but the changes will not be replicated to the master server.

This structure simplifies implementation by avoiding write conflicts, as _**only the master node handles write**_ transactions.

In the master-slave model, one database (the master) is the primary source of truth, while other databases (the slaves) replicate data from the master. An example is a blogging platform where the master database handles content creation, while slaves distribute read requests, ensuring fast and scalable access to articles.

### Primary - Primary (Master - Master) replication

> Data can be copied from either server to the other one. This setup adds redundancy and increases efficiency, especially when dealing with accessing the data

In a Master-Master replication scheme, any of the MariaDB/MySQL database servers may be used both to write or read data. 

Replication is based on a special binlog file, a Master server saves all operations with the database to. A Slave server connects to the Master and applies the commands to its databases.

Master-master replication allows multiple databases to act as both sources and targets of replication.

This architecture is suitable for collaborative platforms, where users worldwide can simultaneously edit documents, such as in Google Docs. Changes made in one document are replicated to all instances, allowing real-time collaboration.

### Synchrone et asynchrone

*   **Asynchronous** replication is when the data is sent to the _model_ (Master/Primary) server -- the server that the replicas take data from -- from the client. Then, the model server pings the client with confirmation saying the data has been received. From there, it goes about copying data to the replicas at an unspecified or monitored pace.  
    Enhancing performance, asynchronous replication allows the leader to proceed with operations without immediate acknowledgment from followers. This approach reduces write latency but risks data loss if the leader fails before followers are updated, leading to eventual consistency challenges.
*   **Synchronous** replication is when data is copied from the client server to the model server and then replicated to all the replica servers _before_ the client is notified that data has been replicated. This takes longer to verify than the asynchronous method, but it presents the advantage of knowing that all data was copied before proceeding.

### Par journaux / par système de fichier

#### Par journaux (log)

Les serveurs primaire et de standby travaillent de concert, bien que les serveurs ne soient que faiblement couplés. Le serveur primaire opère en mode d'archivage en continu, tandis que le serveur de standby opère en mode de récupération en continu, en lisant les fichiers WAL provenant du primaire. Aucune modification des tables de la base ne sont requises pour activer cette fonctionnalité, elle entraîne donc moins de travail d'administration par rapport à d'autres solutions de réplication. Cette configuration a aussi un impact relativement faible sur les performances du serveur primaire.

Déplacer directement des enregistrements de WAL d'un serveur de bases de données à un autre est habituellement appelé log shipping.

Il convient de noter que le log shipping est asynchrone, c'est à dire que les enregistrements de WAL sont transférés après que la transaction ait été validée. Par conséquent, il y a un laps de temps pendant lequel une perte de données pourrait se produire si le serveur primaire subissait un incident majeur; les transactions pas encore transférées seront perdues.

#### Par système de fichiers

Toutes les modifications d'un système de fichiers sont renvoyées sur un système de fichiers situé sur un autre ordinateur. La seule restriction est que ce miroir doit être construit de telle sorte que le serveur en attente dispose d'une version cohérente du système de fichiers -- spécifiquement, les écritures sur le serveur en attente doivent être réalisées dans le même ordre que celles sur le primaire. DRBD est une solution populaire de réplication de systèmes de fichiers pour Linux.

### SQL/NoSQL

#### What is a SQL database?

SQL, is used for querying relational databases, where data is stored in rows and tables that are linked in various ways. 

One table record may link to one other or to many others, or many table records may be related to many records in another table. These relational databases, which offer fast data storage and recovery, can handle great amounts of data and complex SQL queries.

RDBMS (SGBD en français), which use SQL, must exhibit four properties, known by the acronym **ACID**. These ensure that transactions are processed successfully and that the SQL database has a high level of reliability:

*   **A****tomicity:** All transactions must succeed or fail completely and cannot be left partially complete, even in the case of system failure.
*   **C****onsistency:** The database must follow rules that validate and prevent corruption at every step.
*   **I****solation:** Concurrent transactions cannot affect each other.
*   **D****urability:** Transactions are final, and even system failure cannot “roll back” a complete transaction.

#### What is a NoSQL database?

[NoSQL](https://www.ibm.com/cloud/learn/nosql-databases) is a non-relational database, meaning it allows different structures than a SQL database (not rows and columns) and more flexibility to use a format that best fits the data. The term “NoSQL” doesn’t mean the systems don’t use SQL, as NoSQL databases do sometimes support some SQL commands. More accurately, “NoSQL” is sometimes defined as “not only SQL.”

Because they allow a dynamic schema for unstructured data, there’s less need to pre-plan and pre-organize data, and it’s easier to make modifications. NoSQL databases allow you to add new attributes and fields, as well as use varied syntax across databases.

NoSQL databases are not relational, so they don’t solely store data in rows and tables. Instead, they generally fall into one of four types of structures:

*   **Column-oriented,** where data is stored in cells grouped in a virtually unlimited number of columns rather than rows.
*   **Key-value stores**, which use an associative array (also known as a dictionary or map) as their data model. This model represents data as a collection of key-value pairs.
*   **Document stores**, which use documents to hold and encode data in standard formats, including XML, YAML, JSON (JavaScript Object Notation) and BSON. A benefit is that documents within a single database can have different data types.
*   **Graph databases**, which represent data on a graph that shows how different sets of data relate to each other. Neo4j, RedisGraph (a graph module built into Redis) and OrientDB are examples of graph databases.

While SQL calls for ACID properties, NoSQL follows the **CAP** theory (although some NoSQL databases — such as IBM’s DB2, MongoDB, AWS’s DynamoDB and Apache’s CouchDB — can also integrate and follow ACID rules).

The [CAP theorem](https://www.ibm.com/cloud/learn/cap-theorem) says that distributed data systems allow a trade-off that can guarantee only two of the following three properties (which form the acronym CAP) at any one time:

*   **Consistency:** Every request receives either the most recent result or an error. MongoDB is an example of a strongly consistent system, whereas others such as Cassandra offer eventual consistency.
*   **Availability:** Every request has a non-error result.
*   **Partition tolerance:** Any delays or losses between nodes do not interrupt the system operation.