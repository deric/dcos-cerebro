# DC/OS Cerebro

A DC/OS package for [Cerebro](https://github.com/lmenezes/cerebro) web interface for Elasticsearch.


## Boostrap

`bootstrap.sh` generates a Cerebro config file. Configuration is accepted via `ENV` variables. Supported variables are:

* `CEREBRO_REST_HIST_SIZE` - REST history size
* `CEREBRO_SECRET` - secret used for signing session cookies, CSRF tokens and for other encryption utilities
* `CEREBRO_DB_DRIVER` default: `org.sqlite.JDBC`
* `CEREBRO_DB_URL` default: `jdbc:sqlite:./cerebro.db`

### ES clusters

Multiple clusters can be predefined. For each cluster you can define:

* `ES_1` URI to master node, e.g. `http://localhost:9200`
* `ES_1_NAME` human readable name of cluster
* `ES_1_USER` username
* `ES_1_PASS` password

### Authentication

* `CEREBRO_AUTH` one of `none`, `basic` or `ldap`

#### Basic

* `CEREBRO_BASIC_USER` usename
* `CEREBRO_BASIC_PASS` password

#### LDAP

* `CEREBRO_LDAP_URL`
* `CEREBRO_LDAP_BASE`
* `CEREBRO_LDAP_METHOD`
* `CEREBRO_LDAP_DOMAIN`