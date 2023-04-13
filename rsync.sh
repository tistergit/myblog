#!/bin/sh
rsync -avz --delete --exclude='.git/' -e 'ssh -p 22' public  tister@www.tister.cn:/data/myblog

