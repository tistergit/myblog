#!/bin/sh
rsync -avz --delete --exclude='.git/' -e 'ssh -p 22' content static  tister@www.tister.cn:/data/myblog

