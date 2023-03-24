#!/bin/bash

### Eteins le conteneur prod ###
lxc stop prod

### Supprime le conteneur prod ###
lxc delete prod

### Renomme le conteneur de rollback en conteneur de prod ###
lxc rename rollback prod

### Allume le conteneur prod ###
lxc start prod